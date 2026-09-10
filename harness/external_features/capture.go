package main

import (
	"bytes"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"io"
	"math"
	"math/big"
	"net"
	"net/url"
	"sort"
	"strconv"
	"strings"
	"unicode/utf8"
)

type object = map[string]any
type metricStream struct {
	Metric                 object
	Resource, Scope        object
	ResourceSchema, Schema string
	Group                  int
}
type spanStream struct {
	Span                   object
	Resource, Scope        object
	ResourceSchema, Schema string
}
type logStream struct {
	Record                 object
	Resource, Scope        object
	ResourceSchema, Schema string
}
type capture struct {
	Records                         []object
	Spans, Logs, Metrics, Resources []object
	SpanStreams                     []spanStream
	MetricStreams                   []metricStream
	LogStreams                      []logStream
}

// The sink preserves both protobuf's snake_case and OTLP JSON's camelCase.
func canonical(s string) string { return strings.ToLower(strings.ReplaceAll(s, "_", "")) }
func field(o object, name string) any {
	for k, v := range o {
		if canonical(k) == canonical(name) {
			return v
		}
	}
	return nil
}
func objects(v any, name string) []object {
	var found []object
	var walk func(any)
	walk = func(v any) {
		switch v := v.(type) {
		case map[string]any:
			for k, child := range v {
				if canonical(k) == canonical(name) {
					switch child := child.(type) {
					case []any:
						for _, item := range child {
							if o, ok := item.(map[string]any); ok {
								found = append(found, o)
							}
						}
					case map[string]any:
						found = append(found, child)
					}
				} else {
					walk(child)
				}
			}
		case []any:
			for _, child := range v {
				walk(child)
			}
		}
	}
	walk(v)
	return found
}
func decodeCapture(data []byte) (capture, error) {
	var records []object
	decoder := json.NewDecoder(bytes.NewReader(data))
	decoder.UseNumber()
	if err := decoder.Decode(&records); err != nil {
		return capture{}, err
	}
	var trailing any
	if err := decoder.Decode(&trailing); err != io.EOF {
		if err == nil {
			err = fmt.Errorf("unexpected trailing JSON value")
		}
		return capture{}, err
	}
	c := capture{Records: records}
	metricGroupOffset := 0
	for _, r := range records {
		p := field(r, "payload")
		signal, _ := field(r, "signal").(string)
		switch signal {
		case "traces":
			streams := spanStreams(p)
			c.SpanStreams = append(c.SpanStreams, streams...)
			for _, stream := range streams {
				c.Spans = append(c.Spans, stream.Span)
			}
		case "logs":
			streams := logStreams(p)
			c.LogStreams = append(c.LogStreams, streams...)
			for _, stream := range streams {
				c.Logs = append(c.Logs, stream.Record)
			}
		case "metrics":
			streams := metricStreams(p)
			maxGroup := -1
			for index := range streams {
				streams[index].Group += metricGroupOffset
				if streams[index].Group > maxGroup {
					maxGroup = streams[index].Group
				}
			}
			if maxGroup >= metricGroupOffset {
				metricGroupOffset = maxGroup + 1
			}
			c.MetricStreams = append(c.MetricStreams, streams...)
			for _, stream := range streams {
				c.Metrics = append(c.Metrics, stream.Metric)
			}
		default:
			return capture{}, fmt.Errorf("unknown signal %v", signal)
		}
		c.Resources = append(c.Resources, signalResources(p, signal)...)
	}
	return c, nil
}

func signalResources(payload any, signal string) []object {
	container := map[string]string{"traces": "resource_spans", "logs": "resource_logs", "metrics": "resource_metrics"}[signal]
	var resources []object
	for _, envelope := range objects(payload, container) {
		resource, _ := field(envelope, "resource").(map[string]any)
		if resource == nil {
			resource = object{}
		}
		resources = append(resources, resource)
	}
	return resources
}

func metricStreams(payload any) []metricStream {
	var streams []metricStream
	group := 0
	for _, resourceMetrics := range objects(payload, "resource_metrics") {
		resource, _ := field(resourceMetrics, "resource").(map[string]any)
		resourceSchema, _ := field(resourceMetrics, "schema_url").(string)
		for _, scopeMetrics := range objects(resourceMetrics, "scope_metrics") {
			scope, _ := field(scopeMetrics, "scope").(map[string]any)
			schema, _ := field(scopeMetrics, "schema_url").(string)
			for _, metric := range objects(scopeMetrics, "metrics") {
				streams = append(streams, metricStream{Metric: metric, Resource: resource, Scope: scope, ResourceSchema: resourceSchema, Schema: schema, Group: group})
			}
			group++
		}
	}
	return streams
}

func spanStreams(payload any) []spanStream {
	var streams []spanStream
	for _, resourceSpans := range objects(payload, "resource_spans") {
		resource, _ := field(resourceSpans, "resource").(map[string]any)
		resourceSchema, _ := field(resourceSpans, "schema_url").(string)
		for _, scopeSpans := range objects(resourceSpans, "scope_spans") {
			scope, _ := field(scopeSpans, "scope").(map[string]any)
			schema, _ := field(scopeSpans, "schema_url").(string)
			for _, span := range objects(scopeSpans, "spans") {
				streams = append(streams, spanStream{Span: span, Resource: resource, Scope: scope, ResourceSchema: resourceSchema, Schema: schema})
			}
		}
	}
	return streams
}

func logStreams(payload any) []logStream {
	var streams []logStream
	for _, resourceLogs := range objects(payload, "resource_logs") {
		resource, _ := field(resourceLogs, "resource").(map[string]any)
		resourceSchema, _ := field(resourceLogs, "schema_url").(string)
		for _, scopeLogs := range objects(resourceLogs, "scope_logs") {
			scope, _ := field(scopeLogs, "scope").(map[string]any)
			schema, _ := field(scopeLogs, "schema_url").(string)
			for _, record := range objects(scopeLogs, "log_records") {
				streams = append(streams, logStream{Record: record, Resource: resource, Scope: scope, ResourceSchema: resourceSchema, Schema: schema})
			}
		}
	}
	return streams
}
func attributes(o object) []object {
	var out []object
	if attrs, ok := field(o, "attributes").([]any); ok {
		for _, a := range attrs {
			if a, ok := a.(map[string]any); ok {
				out = append(out, a)
			}
		}
	}
	return out
}
func number(v any) float64 {
	if n, ok := otlpNumber(v); ok {
		return n
	}
	return 0
}
func stringValue(v any) (string, bool) {
	if o, ok := v.(map[string]any); ok {
		if s, ok := field(o, "string_value").(string); ok {
			return s, true
		}
		return stringValue(field(o, "value"))
	}
	return "", false
}
func attributeValue(o object, key string) string {
	for _, a := range attributes(o) {
		if field(a, "key") == key {
			s, _ := stringValue(field(a, "value"))
			return s
		}
	}
	return ""
}
func stringAttribute(o object, key string) (string, bool, bool) {
	found, valid, value := false, false, ""
	for _, a := range attributes(o) {
		if field(a, "key") != key {
			continue
		}
		if found {
			return "", true, false
		}
		found = true
		value, valid = stringValue(field(a, "value"))
	}
	return value, found, valid
}
func events(c capture) []object {
	var out []object
	for _, s := range c.Spans {
		out = append(out, objects(s, "events")...)
	}
	return out
}
func maxAttributes(items []object) int {
	n := 0
	for _, o := range items {
		if size := len(attributes(o)); size > n {
			n = size
		}
	}
	return n
}
func maxLength(items []object) int {
	n := 0
	for _, o := range items {
		for _, a := range attributes(o) {
			if size := maxStringValueLength(field(a, "value")); size > n {
				n = size
			}
		}
	}
	return n
}
func maxStringValueLength(v any) int {
	n := 0
	switch v := v.(type) {
	case map[string]any:
		for key, child := range v {
			if canonical(key) == canonical("string_value") {
				if value, ok := child.(string); ok {
					n = utf8.RuneCountInString(value)
				}
				continue
			}
			if size := maxStringValueLength(child); size > n {
				n = size
			}
		}
	case []any:
		for _, child := range v {
			if size := maxStringValueLength(child); size > n {
				n = size
			}
		}
	}
	return n
}
func normalizedStringValueID(v any, limit int) (string, bool) {
	normalized, found := normalizeStringValues(v, limit)
	encoded, _ := json.Marshal(normalized)
	return string(encoded), found
}
func normalizeStringValues(v any, limit int) (any, bool) {
	switch v := v.(type) {
	case map[string]any:
		if len(v) == 1 {
			for key, child := range v {
				if canonical(key) == "value" {
					return normalizeStringValues(child, limit)
				}
			}
		}
		normalized := make(map[string]any, len(v))
		found := false
		for key, child := range v {
			if canonical(key) == canonical("string_value") {
				value, ok := child.(string)
				if ok {
					runes := []rune(value)
					if limit >= 0 && len(runes) > limit {
						value = string(runes[:limit])
					}
					found = true
					normalized[canonical(key)] = value
				} else {
					normalized[canonical(key)] = child
				}
				continue
			}
			normalizedChild, childFound := normalizeStringValues(child, limit)
			normalized[canonical(key)] = normalizedChild
			found = found || childFound
		}
		return normalized, found
	case []any:
		normalized := make([]any, len(v))
		found := false
		for i, child := range v {
			var childFound bool
			normalized[i], childFound = normalizeStringValues(child, limit)
			found = found || childFound
		}
		return normalized, found
	}
	return v, false
}
func dropped(items []object, key string) int {
	n := 0
	for _, o := range items {
		n += int(number(field(o, key)))
	}
	return n
}
func metricObjects(c capture, kind string) []object {
	var out []object
	for _, m := range c.Metrics {
		out = append(out, objects(m, kind)...)
	}
	return out
}

type observation struct {
	Case       string   `json:"case"`
	Features   []string `json:"features"`
	Status     string   `json:"status"`
	Detail     string   `json:"detail"`
	Violations []string `json:"violations,omitempty"`
}

func (o observation) signature() string {
	if o.Status == "gap" && len(o.Violations) > 0 {
		return o.Status + ":" + strings.Join(o.Violations, ",")
	}
	return o.Status
}

func evaluate(e experiment, baseline, changed capture) observation {
	o := observation{Case: e.Name, Features: e.Features, Status: "gap"}
	check := func(prerequisite, success bool, detail string) {
		o.Detail = detail
		if !prerequisite {
			o.Status = "not_exercised"
		} else if success {
			o.Status = "pass"
		}
	}
	switch e.Name {
	case "default-service":
		ok := len(changed.Resources) > 0
		beforeProbes, afterProbes := probeSpans(baseline), probeSpans(changed)
		expectedRequests, presentRequests := preservedProbeRequests(baseline, changed)
		ignoredResourceAttributes := map[string]bool{"service.name": true}
		expectedWorkloadSpans, presentWorkloadSpans := matchingWorkloadSpansIgnoring(baseline, changed, ignoredResourceAttributes)
		expectedMetrics, presentMetrics := matchingMetricStreamsIgnoring(baseline, changed, ignoredResourceAttributes)
		expectedLogs, presentLogs := matchingLogStreams(baseline, changed, ignoredResourceAttributes)
		preserved := (len(baseline.Spans) == 0 || (expectedWorkloadSpans > 0 && presentWorkloadSpans == expectedWorkloadSpans)) &&
			(len(baseline.Logs) == 0 || (expectedLogs > 0 && presentLogs == expectedLogs)) &&
			(len(baseline.Metrics) == 0 || (expectedMetrics > 0 && presentMetrics == expectedMetrics)) &&
			(len(beforeProbes) == 0 || (len(afterProbes) == len(beforeProbes) && presentRequests == expectedRequests))
		violations := map[string]bool{}
		for _, r := range changed.Resources {
			name, present, valid := stringAttribute(r, "service.name")
			executable := attributeValue(r, "process.executable.name")
			validDefault := valid && (name == "unknown_service" || (strings.HasPrefix(name, "unknown_service:") && len(name) > len("unknown_service:")))
			if executable != "" {
				validDefault = valid && name == "unknown_service:"+executable
			}
			ok = ok && validDefault
			if !validDefault {
				kind := "malformed"
				if !present {
					kind = "missing"
				} else if valid {
					kind = "unexpected"
					if name == "" {
						kind = "empty"
					}
				}
				violations["service.name="+kind] = true
			}
		}
		if len(baseline.Spans) > 0 && len(changed.Spans) == 0 {
			violations["spans-missing"] = true
		}
		if len(baseline.Logs) > 0 && len(changed.Logs) == 0 {
			violations["logs-missing"] = true
		} else if len(baseline.Logs) > 0 && presentLogs != expectedLogs {
			violations[fmt.Sprintf("logs=%d/%d", presentLogs, expectedLogs)] = true
		}
		if len(baseline.Metrics) > 0 && len(changed.Metrics) == 0 {
			violations["metrics-missing"] = true
		} else if len(baseline.Metrics) > 0 && presentMetrics != expectedMetrics {
			violations[fmt.Sprintf("metrics=%d/%d", presentMetrics, expectedMetrics)] = true
		}
		if len(beforeProbes) > 0 && len(afterProbes) != len(beforeProbes) {
			violations[fmt.Sprintf("probe-spans=%d", len(afterProbes))] = true
		}
		if expectedWorkloadSpans > 0 && presentWorkloadSpans != expectedWorkloadSpans {
			violations[fmt.Sprintf("workload-spans=%d/%d", presentWorkloadSpans, expectedWorkloadSpans)] = true
		}
		if expectedRequests > 0 && presentRequests != expectedRequests {
			violations[fmt.Sprintf("requests=%d", presentRequests)] = true
		}
		for v := range violations {
			o.Violations = append(o.Violations, v)
		}
		sort.Strings(o.Violations)
		check(len(baseline.Resources) > 0, ok && preserved, "empty OTEL_SERVICE_NAME must produce unknown_service or unknown_service:<executable> without losing baseline signals")
	case "span-batch", "log-batch":
		signal, key := "traces", "spans"
		before, after := baseline.Spans, changed.Spans
		if e.Name == "log-batch" {
			signal, key = "logs", "log_records"
			before, after = baseline.Logs, changed.Logs
		}
		prior, actual := maxBatch(baseline, signal, key), maxBatch(changed, signal, key)
		preserved := len(after) >= 2
		if e.Name == "span-batch" {
			probes := probeSpans(changed)
			expected, present := matchingWorkloadSpans(baseline, changed)
			expectedMetrics, presentMetrics := matchingMetricStreams(baseline, changed)
			expectedLogs, presentLogs := matchingLogStreams(baseline, changed, nil)
			preserved = len(probes) == 4 && len(incomingProbeTraces(probes)) == 4 && expected > 0 && present == expected && presentMetrics == expectedMetrics && presentLogs == expectedLogs
		} else {
			expected, present := matchingLogStreams(baseline, changed, nil)
			expectedSpans, presentSpans := matchingWorkloadSpans(baseline, changed)
			expectedMetrics, presentMetrics := matchingMetricStreams(baseline, changed)
			preserved = preserved && expected > 0 && present == expected && presentSpans == expectedSpans && presentMetrics == expectedMetrics
		}
		check(prior > 1, actual == 1 && preserved, fmt.Sprintf("maximum %s batch %d -> %d; records %d -> %d", signal, prior, actual, len(before), len(after)))
		if o.Status == "gap" {
			switch {
			case actual == 0:
				o.Violations = append(o.Violations, "no-batches")
			case actual > 1:
				o.Violations = append(o.Violations, "batch-limit-exceeded")
			}
			if !preserved {
				o.Violations = append(o.Violations, "records-not-preserved")
			}
			sort.Strings(o.Violations)
		}
	case "exemplars-always-on":
		eligible, preserved, after := unsampledExemplars(baseline, changed)
		expectedMetrics, presentMetrics := matchingMetricStreamsIgnoringExemplars(baseline, changed)
		expectedLogs, presentLogs := matchingLogStreams(baseline, changed, nil)
		check(eligible > 0 && len(baseline.Spans) == 0, len(changed.Spans) == 0 && preserved == eligible && after > 0 && presentMetrics == expectedMetrics && presentLogs == expectedLogs, fmt.Sprintf("eligible control points preserved %d/%d; all metric points %d/%d and logs %d/%d preserved; AlwaysOn exemplars %d; exported spans %d", preserved, eligible, presentMetrics, expectedMetrics, presentLogs, expectedLogs, after, len(changed.Spans)))
	case "request-headers":
		before, after := probeSpans(baseline), probeSpans(changed)
		beforeRequests, afterRequests := incomingProbeTraces(before), incomingProbeTraces(after)
		captured, malformed := 0, 0
		for _, s := range after {
			present, exact := headerArrayStatus(s)
			if exact {
				captured++
			} else if present {
				malformed++
			}
		}
		expectedSpans, presentSpans := matchingWorkloadSpansIgnoringHeader(baseline, changed)
		expectedMetrics, presentMetrics := matchingMetricStreams(baseline, changed)
		expectedLogs, presentLogs := matchingLogStreams(baseline, changed, nil)
		preserved := expectedSpans > 0 && presentSpans == expectedSpans && presentMetrics == expectedMetrics && presentLogs == expectedLogs
		check(len(before) == 4 && len(beforeRequests) == 4, len(after) == 4 && len(afterRequests) == 4 && captured == 4 && preserved, fmt.Sprintf("distinct probe requests %d -> %d; server spans %d -> %d; exact header arrays %d/4; workload spans %d/%d, metrics %d/%d, logs %d/%d preserved", len(beforeRequests), len(afterRequests), len(before), len(after), captured, presentSpans, expectedSpans, presentMetrics, expectedMetrics, presentLogs, expectedLogs))
		if o.Status == "gap" {
			if captured != 4 {
				o.Violations = append(o.Violations, fmt.Sprintf("header-arrays=%d", captured))
			}
			if malformed > 0 {
				o.Violations = append(o.Violations, fmt.Sprintf("malformed-headers=%d", malformed))
			}
			if len(afterRequests) != 4 {
				o.Violations = append(o.Violations, fmt.Sprintf("requests=%d", len(afterRequests)))
			}
			if len(after) != 4 {
				o.Violations = append(o.Violations, fmt.Sprintf("probe-spans=%d", len(after)))
			}
			if presentSpans != expectedSpans {
				o.Violations = append(o.Violations, fmt.Sprintf("workload-spans=%d/%d", presentSpans, expectedSpans))
			}
			if presentMetrics != expectedMetrics {
				o.Violations = append(o.Violations, fmt.Sprintf("metrics=%d/%d", presentMetrics, expectedMetrics))
			}
			if presentLogs != expectedLogs {
				o.Violations = append(o.Violations, fmt.Sprintf("logs=%d/%d", presentLogs, expectedLogs))
			}
			sort.Strings(o.Violations)
		}
	case "propagation-none":
		before, after := probeSpans(baseline), probeSpans(changed)
		continued := map[string]bool{}
		roots := map[string]bool{}
		for _, s := range before {
			if id, ok := field(s, "trace_id").(string); ok && incomingTrace(id) && field(s, "parent_span_id") == "00f067aa0ba902b7" {
				continued[id] = true
			}
		}
		for _, s := range after {
			if id, ok := field(s, "trace_id").(string); ok && validTrace(id) && !incomingTrace(id) && field(s, "parent_span_id") == "" {
				roots[id] = true
			}
		}
		expectedSpans, presentSpans := matchingWorkloadSpansIgnoringParents(baseline, changed)
		expectedMetrics, presentMetrics := matchingMetricStreams(baseline, changed)
		expectedLogs, presentLogs := matchingLogStreamsForPropagation(baseline, changed)
		preserved := expectedSpans > 0 && presentSpans == expectedSpans &&
			(len(baseline.Metrics) == 0 || (expectedMetrics > 0 && presentMetrics == expectedMetrics)) &&
			(len(baseline.Logs) == 0 || (expectedLogs > 0 && presentLogs == expectedLogs))
		check(len(before) == 4 && len(continued) == 4, len(after) == 4 && len(roots) == 4 && preserved, fmt.Sprintf("incoming traces continued %d/4; independent roots with propagation disabled %d/4; workload spans %d/%d, metrics %d/%d, logs %d/%d preserved", len(continued), len(roots), presentSpans, expectedSpans, presentMetrics, expectedMetrics, presentLogs, expectedLogs))
	case "resource":
		ok := len(changed.Resources) > 0
		expected, present := preservedProbeRequests(baseline, changed)
		ignoredResourceAttributes := map[string]bool{"probe.external": true, "process.owner": true, "service.name": true}
		expectedWorkloadSpans, presentWorkloadSpans := matchingWorkloadSpansIgnoring(baseline, changed, ignoredResourceAttributes)
		expectedMetrics, presentMetrics := matchingMetricStreamsIgnoring(baseline, changed, ignoredResourceAttributes)
		expectedLogs, presentLogs := matchingLogStreams(baseline, changed, ignoredResourceAttributes)
		preserved := (len(baseline.Spans) == 0 || (expectedWorkloadSpans > 0 && presentWorkloadSpans == expectedWorkloadSpans)) &&
			(len(baseline.Logs) == 0 || (expectedLogs > 0 && presentLogs == expectedLogs)) &&
			(len(baseline.Metrics) == 0 || (expectedMetrics > 0 && presentMetrics == expectedMetrics)) &&
			(expected == 0 || present == expected)
		for _, r := range changed.Resources {
			probeExternal, probePresent, probeValid := stringAttribute(r, "probe.external")
			serviceName, servicePresent, serviceValid := stringAttribute(r, "service.name")
			ok = ok && probePresent && probeValid && probeExternal == "visible" && servicePresent && serviceValid && serviceName == "external-probe"
		}
		check(len(baseline.Resources) > 0, ok && preserved, fmt.Sprintf("%d resources must retain probe.external=visible and OTEL_SERVICE_NAME precedence; workload requests preserved %d/%d", len(changed.Resources), present, expected))
	case "disabled":
		check(len(baseline.Spans) > 0, len(changed.Records) == 0, fmt.Sprintf("export requests %d -> %d", len(baseline.Records), len(changed.Records)))
	case "sampler", "sampler-arg":
		expectedMetrics, presentMetrics := matchingMetricStreamsIgnoringExemplars(baseline, changed)
		expectedLogs, presentLogs := matchingLogStreamsForSampler(baseline, changed)
		otherSignalsAlive := (len(baseline.Metrics) == 0 || (expectedMetrics > 0 && presentMetrics == expectedMetrics)) &&
			(len(baseline.Logs) == 0 || (expectedLogs > 0 && presentLogs == expectedLogs))
		check(len(baseline.Spans) > 0, len(changed.Spans) == 0 && otherSignalsAlive, fmt.Sprintf("spans %d -> %d; other baseline signals still exported: %t", len(baseline.Spans), len(changed.Spans), otherSignalsAlive))
	case "span-length", "attribute-length", "log-length":
		before, after := baseline.Spans, changed.Spans
		preserved, expected, present := true, 0, 0
		attributeExpected, attributePresent, attributeMissing := 0, 0, 0
		if e.Name == "log-length" {
			before, after = baseline.Logs, changed.Logs
			expected, present = matchingLengthLimitedLogStreams(baseline, changed, 8)
			attributeExpected, attributePresent, attributeMissing = preservedLongLogAttributes(baseline, changed, 8)
			expectedSpans, presentSpans := matchingWorkloadSpans(baseline, changed)
			expectedMetrics, presentMetrics := matchingMetricStreams(baseline, changed)
			preserved = expected > 0 && present == expected && attributeExpected > 0 && attributePresent == attributeExpected && presentSpans == expectedSpans && presentMetrics == expectedMetrics
		} else {
			expectedTraces := incomingProbeTraces(probeSpans(baseline))
			presentTraces := incomingServerTraces(after)
			expected, present = matchingLengthLimitedWorkloadSpans(baseline, changed, 8, e.Name == "attribute-length")
			attributeExpected, attributePresent, attributeMissing = preservedLongSpanAttributes(baseline, changed, 8)
			expectedMetrics, presentMetrics := matchingMetricStreams(baseline, changed)
			expectedLogs, presentLogs := matchingLogStreams(baseline, changed, nil)
			if e.Name == "attribute-length" {
				before = append(append(append([]object{}, baseline.Spans...), baseline.Logs...), events(baseline)...)
				after = append(append(append([]object{}, changed.Spans...), changed.Logs...), events(changed)...)
				expectedLogs, presentLogs = matchingLengthLimitedLogStreams(baseline, changed, 8)
				logAttributeExpected, logAttributePresent, logAttributeMissing := preservedLongLogAttributes(baseline, changed, 8)
				attributeExpected += logAttributeExpected
				attributePresent += logAttributePresent
				attributeMissing += logAttributeMissing
				expectedEvents, presentEvents := matchingLengthLimitedEvents(baseline, changed, 8)
				eventAttributeExpected, eventAttributePresent, eventAttributeMissing := preservedLongEventAttributes(baseline, changed, 8)
				attributeExpected += eventAttributeExpected
				attributePresent += eventAttributePresent
				attributeMissing += eventAttributeMissing
				preserved = expectedEvents == presentEvents
			}
			preserved = preserved && len(expectedTraces) == 4 && len(presentTraces) == len(expectedTraces) && expected > 0 && present == expected && attributeExpected > 0 && attributePresent == attributeExpected && presentMetrics == expectedMetrics && presentLogs == expectedLogs
		}
		check(maxLength(before) > 8, len(after) > 0 && maxLength(after) == 8 && preserved, fmt.Sprintf("maximum string attribute length %d -> %d; cap 8; baseline record identities preserved %d/%d; long attributes preserved %d/%d", maxLength(before), maxLength(after), present, expected, attributePresent, attributeExpected))
		violations := map[string]bool{}
		for _, item := range after {
			for _, a := range attributes(item) {
				if size := maxStringValueLength(field(a, "value")); size > 8 {
					violations[fmt.Sprintf("%v=%d", field(a, "key"), size)] = true
				}
			}
		}
		for v := range violations {
			o.Violations = append(o.Violations, v)
		}
		if present != expected {
			o.Violations = append(o.Violations, fmt.Sprintf("records=%d/%d", present, expected))
		}
		if attributeMissing > 0 {
			o.Violations = append(o.Violations, fmt.Sprintf("attributes=%d/%d", attributePresent, attributeExpected))
		}
		if e.Name == "log-length" {
			expectedSpans, presentSpans := matchingWorkloadSpans(baseline, changed)
			expectedMetrics, presentMetrics := matchingMetricStreams(baseline, changed)
			if presentSpans != expectedSpans {
				o.Violations = append(o.Violations, fmt.Sprintf("workload-spans=%d/%d", presentSpans, expectedSpans))
			}
			if presentMetrics != expectedMetrics {
				o.Violations = append(o.Violations, fmt.Sprintf("metrics=%d/%d", presentMetrics, expectedMetrics))
			}
		} else {
			expectedMetrics, presentMetrics := matchingMetricStreams(baseline, changed)
			expectedLogs, presentLogs := matchingLogStreams(baseline, changed, nil)
			if e.Name == "attribute-length" {
				expectedLogs, presentLogs = matchingLengthLimitedLogStreams(baseline, changed, 8)
			}
			if presentMetrics != expectedMetrics {
				o.Violations = append(o.Violations, fmt.Sprintf("metrics=%d/%d", presentMetrics, expectedMetrics))
			}
			if presentLogs != expectedLogs {
				o.Violations = append(o.Violations, fmt.Sprintf("logs=%d/%d", presentLogs, expectedLogs))
			}
		}
		sort.Strings(o.Violations)
	case "attribute-count", "event-attributes", "log-count":
		before, after, cap := baseline.Spans, changed.Spans, 2
		preserved, expected, present := true, 0, 0
		affectedSpansExpected, affectedSpansPresent := 0, 0
		affectedLogsExpected, affectedLogsPresent := 0, 0
		affectedEventsExpected, affectedEventsPresent := 0, 0
		if e.Name == "event-attributes" {
			before, after, cap = events(baseline), events(changed), 1
			expected, present = limitedEventRecords(baseline, changed, cap)
			allExpected, allPresent := matchingCountLimitedEvents(baseline, changed, cap)
			preserved = (expected == 0 || present == expected) && allPresent == allExpected
		}
		if e.Name == "log-count" {
			before, after, cap = baseline.Logs, changed.Logs, 1
			expected, present = limitedCountLogStreamRecords(baseline, changed, cap)
			allExpected, allPresent := matchingCountLimitedLogStreams(baseline, changed, cap)
			preserved = (expected == 0 || present == expected) && allPresent == allExpected
		} else if e.Name != "event-attributes" {
			expectedProbes, presentProbes := limitedProbeRequests(baseline, changed, cap)
			expected, present = matchingCountLimitedWorkloadSpans(baseline, changed)
			preserved = expectedProbes > 0 && presentProbes == expectedProbes && expected > 0 && present == expected
			before = append(append(append([]object{}, baseline.Spans...), baseline.Logs...), events(baseline)...)
			after = append(append(append([]object{}, changed.Spans...), changed.Logs...), events(changed)...)
			affectedLogsExpected, affectedLogsPresent = limitedCountLogStreamRecords(baseline, changed, cap)
			affectedSpansExpected, affectedSpansPresent = limitedGlobalCountSpanRecords(baseline, changed, cap)
			affectedEventsExpected, affectedEventsPresent = limitedGlobalCountEventRecords(baseline, changed, cap)
			expectedEvents, presentEvents := matchingGlobalCountLimitedEvents(baseline, changed, cap)
			preserved = preserved && affectedSpansPresent == affectedSpansExpected && affectedLogsPresent == affectedLogsExpected && affectedEventsPresent == affectedEventsExpected && presentEvents == expectedEvents
		}
		expectedSpans, presentSpans := matchingWorkloadSpans(baseline, changed)
		if e.Name == "attribute-count" {
			expectedSpans, presentSpans = matchingCountLimitedWorkloadSpans(baseline, changed)
		} else if e.Name == "event-attributes" {
			expectedSpans, presentSpans = matchingWorkloadSpansIgnoringEvents(baseline, changed)
		}
		expectedMetrics, presentMetrics := matchingMetricStreams(baseline, changed)
		expectedLogs, presentLogs := matchingLogStreams(baseline, changed, nil)
		if e.Name == "log-count" || e.Name == "attribute-count" {
			expectedLogs, presentLogs = matchingCountLimitedLogStreams(baseline, changed, cap)
		}
		preserved = preserved && presentSpans == expectedSpans && presentMetrics == expectedMetrics && presentLogs == expectedLogs
		prerequisite := maxAttributes(before) > cap
		if e.Name == "attribute-count" || e.Name == "event-attributes" || e.Name == "log-count" {
			prerequisite = prerequisite && expected > 0
		}
		check(prerequisite, len(after) > 0 && maxAttributes(after) == cap && dropped(after, "dropped_attributes_count") > 0 && preserved, fmt.Sprintf("maximum attributes %d -> %d; cap %d; dropped %d; affected records %d/%d; affected spans %d/%d; affected logs %d/%d; affected events %d/%d; workload spans %d/%d, metrics %d/%d, logs %d/%d preserved", maxAttributes(before), maxAttributes(after), cap, dropped(after, "dropped_attributes_count"), present, expected, affectedSpansPresent, affectedSpansExpected, affectedLogsPresent, affectedLogsExpected, affectedEventsPresent, affectedEventsExpected, presentSpans, expectedSpans, presentMetrics, expectedMetrics, presentLogs, expectedLogs))
	case "events":
		expected, present := suppressedEventRecords(baseline, changed)
		expectedSpans, presentSpans := matchingWorkloadSpansIgnoringEvents(baseline, changed)
		expectedMetrics, presentMetrics := matchingMetricStreams(baseline, changed)
		expectedLogs, presentLogs := matchingLogStreams(baseline, changed, nil)
		preserved := (expected == 0 || present == expected) && presentSpans == expectedSpans && presentMetrics == expectedMetrics && presentLogs == expectedLogs
		check(len(events(baseline)) > 0, len(changed.Spans) > 0 && len(events(changed)) == 0 && dropped(changed.Spans, "dropped_events_count") > 0 && preserved, fmt.Sprintf("events %d -> %d; dropped %d; workload requests preserved %d/%d", len(events(baseline)), len(events(changed)), dropped(changed.Spans, "dropped_events_count"), present, expected))
	case "exemplars":
		before, preserved, remaining := suppressedExemplars(baseline, changed)
		expectedMetrics, presentMetrics := matchingMetricStreamsIgnoringExemplars(baseline, changed)
		expectedSpans, presentSpans := matchingWorkloadSpans(baseline, changed)
		expectedLogs, presentLogs := matchingLogStreams(baseline, changed, nil)
		signalsPreserved := expectedMetrics > 0 && presentMetrics == expectedMetrics &&
			(len(baseline.Spans) == 0 || (expectedSpans > 0 && presentSpans == expectedSpans)) &&
			(len(baseline.Logs) == 0 || (expectedLogs > 0 && presentLogs == expectedLogs))
		check(before > 0, preserved == before && remaining == 0 && signalsPreserved, fmt.Sprintf("exemplar-bearing metric identities preserved %d/%d; all metric points %d/%d, workload spans %d/%d, logs %d/%d preserved; remaining exemplars %d", preserved, before, presentMetrics, expectedMetrics, presentSpans, expectedSpans, presentLogs, expectedLogs, remaining))
	case "histogram":
		before, converted := convertedHistograms(baseline, changed)
		remaining := len(metricObjects(changed, "histogram"))
		expectedMetrics, presentMetrics := matchingNonHistogramMetricStreams(baseline, changed)
		expectedSpans, presentSpans := matchingWorkloadSpans(baseline, changed)
		expectedLogs, presentLogs := matchingLogStreams(baseline, changed, nil)
		preserved := presentMetrics == expectedMetrics && presentSpans == expectedSpans && presentLogs == expectedLogs
		check(before > 0, converted == before && remaining == 0 && preserved, fmt.Sprintf("baseline histogram identities converted %d/%d; non-histogram points %d/%d, workload spans %d/%d, logs %d/%d preserved; remaining explicit exports %d", converted, before, presentMetrics, expectedMetrics, presentSpans, expectedSpans, presentLogs, expectedLogs, remaining))
		if before == 0 && (len(baseline.Metrics) > 0 || len(baseline.Spans) > 0 || len(baseline.Logs) > 0) && !preserved {
			o.Status = "gap"
		}
	default:
		panic("unknown experiment: " + e.Name)
	}
	return o
}

func maxBatch(c capture, signal, key string) int {
	max := 0
	for _, r := range c.Records {
		if field(r, "signal") == signal {
			if n := len(objects(field(r, "payload"), key)); n > max {
				max = n
			}
		}
	}
	return max
}
func probeSpans(c capture) []object {
	var out []object
	for _, s := range c.Spans {
		if number(field(s, "kind")) == 2 && (attributeValue(s, "http.user_agent") == "external-feature-probe-long-user-agent" || attributeValue(s, "user_agent.original") == "external-feature-probe-long-user-agent") {
			out = append(out, s)
		}
	}
	return out
}
func incomingTrace(id string) bool {
	for i := 1; i <= 4; i++ {
		if id == fmt.Sprintf("%032x", i) {
			return true
		}
	}
	return false
}
func incomingProbeTraces(spans []object) map[string]bool {
	traces := map[string]bool{}
	for _, s := range spans {
		if id, ok := field(s, "trace_id").(string); ok && incomingTrace(id) {
			traces[id] = true
		}
	}
	return traces
}
func incomingServerTraces(spans []object) map[string]bool {
	traces := map[string]bool{}
	for _, s := range spans {
		if number(field(s, "kind")) != 2 {
			continue
		}
		if id, ok := field(s, "trace_id").(string); ok && incomingTrace(id) {
			traces[id] = true
		}
	}
	return traces
}
func preservedProbeRequests(before, after capture) (int, int) {
	expected := incomingProbeTraces(probeSpans(before))
	present := incomingServerTraces(after.Spans)
	return len(expected), len(present)
}

func matchingWorkloadSpans(before, after capture) (int, int) {
	return matchingWorkloadSpansIgnoring(before, after, nil)
}

func matchingWorkloadSpansIgnoring(before, after capture, ignoredResourceAttributes map[string]bool) (int, int) {
	return matchingWorkloadSpansWithID(before, after, ignoredResourceAttributes, workloadSpanID, true)
}

func matchingWorkloadSpansIgnoringParents(before, after capture) (int, int) {
	eligible := workloadSpanIdentitiesWithParentID(before, nil, workloadSpanIDForPropagation, spanParentRelationshipIDForPropagation)
	actual := workloadSpanIdentitiesWithParentID(after, nil, workloadSpanIDForPropagation, spanParentRelationshipIDForPropagation)
	return matchingWorkloadIdentityCounts(eligible, actual, before, after)
}

func matchingWorkloadSpansIgnoringEvents(before, after capture) (int, int) {
	return matchingWorkloadSpansWithID(before, after, nil, workloadSpanIDIgnoringEvents, true)
}

func matchingWorkloadSpansIgnoringHeader(before, after capture) (int, int) {
	return matchingWorkloadSpansWithID(before, after, nil, workloadSpanIDIgnoringHeader, true)
}

func matchingLengthLimitedWorkloadSpans(before, after capture, limit int, limitEvents bool) (int, int) {
	return matchingWorkloadSpansWithID(before, after, nil, func(span object) string {
		return workloadSpanIDWithStringLimit(span, limit, limitEvents)
	}, true)
}

func matchingCountLimitedWorkloadSpans(before, after capture) (int, int) {
	return matchingWorkloadSpansWithID(before, after, nil, func(span object) string {
		return workloadSpanIDForCountLimit(span, 2)
	}, true)
}

func matchingWorkloadSpansWithID(before, after capture, ignoredResourceAttributes map[string]bool, identify func(object) string, includeParent bool) (int, int) {
	eligible := workloadSpanIdentitiesWithID(before, ignoredResourceAttributes, identify, includeParent)
	actual := workloadSpanIdentitiesWithID(after, ignoredResourceAttributes, identify, includeParent)
	return matchingWorkloadIdentityCounts(eligible, actual, before, after)
}

func matchingWorkloadIdentityCounts(eligible, actual map[string]int, baseline, changed capture) (int, int) {
	expected, present := matchingIdentityCounts(eligible, actual)
	if (!validWorkloadSpanStructure(changed) || !sameIdentityCounts(workloadTracePartitions(baseline), workloadTracePartitions(changed))) && present == expected {
		present = expected + 1
	}
	return expected, present
}

func sameIdentityCounts(left, right map[string]int) bool {
	if len(left) != len(right) {
		return false
	}
	for id, count := range left {
		if right[id] != count {
			return false
		}
	}
	return true
}

func workloadTracePartitions(c capture) map[string]int {
	traceIDs := map[string]bool{}
	for _, stream := range captureSpanStreams(c) {
		if isProbeServerSpan(stream.Span) {
			traceID, _ := field(stream.Span, "trace_id").(string)
			if validTrace(traceID) {
				traceIDs[traceID] = true
			}
		}
	}
	type partition struct {
		spans, servers, roots int
		spanIDs               map[string]bool
		parentIDs             []string
	}
	partitions := map[string]*partition{}
	for _, stream := range captureSpanStreams(c) {
		traceID, _ := field(stream.Span, "trace_id").(string)
		if !traceIDs[traceID] {
			continue
		}
		current := partitions[traceID]
		if current == nil {
			current = &partition{spanIDs: map[string]bool{}}
			partitions[traceID] = current
		}
		current.spans++
		if isProbeServerSpan(stream.Span) {
			current.servers++
		}
		spanID, _ := field(stream.Span, "span_id").(string)
		current.spanIDs[spanID] = true
		parentID, _ := field(stream.Span, "parent_span_id").(string)
		current.parentIDs = append(current.parentIDs, parentID)
	}
	counts := map[string]int{}
	for _, current := range partitions {
		for _, parentID := range current.parentIDs {
			if !current.spanIDs[parentID] {
				current.roots++
			}
		}
		encoded, _ := json.Marshal([]int{current.spans, current.servers, current.roots})
		counts[string(encoded)]++
	}
	return counts
}

func validSamplerControl(c capture) bool {
	probes := probeSpans(c)
	return len(probes) == 4 && len(incomingProbeTraces(probes)) == 4
}

func validWorkloadSpanStructure(c capture) bool {
	traceIDs := map[string]bool{}
	for _, stream := range captureSpanStreams(c) {
		if !isProbeServerSpan(stream.Span) {
			continue
		}
		traceID, _ := field(stream.Span, "trace_id").(string)
		if !validTrace(traceID) {
			return false
		}
		traceIDs[traceID] = true
	}
	spanIDs := map[string]bool{}
	for _, stream := range captureSpanStreams(c) {
		span := stream.Span
		traceID, _ := field(span, "trace_id").(string)
		if !traceIDs[traceID] {
			continue
		}
		spanID, _ := field(span, "span_id").(string)
		key := traceID + "\x00" + spanID
		start, startValid := otlpTimestamp(field(span, "start_time_unix_nano"))
		end, endValid := otlpTimestamp(field(span, "end_time_unix_nano"))
		if !validSpan(spanID) || spanIDs[key] || !startValid || !endValid || start.Sign() <= 0 || end.Cmp(start) < 0 {
			return false
		}
		spanIDs[key] = true
	}
	return true
}

func workloadSpanIdentities(c capture, ignoredResourceAttributes map[string]bool) map[string]int {
	return workloadSpanIdentitiesWithID(c, ignoredResourceAttributes, workloadSpanID, true)
}

func workloadSpanIdentitiesWithID(c capture, ignoredResourceAttributes map[string]bool, identify func(object) string, includeParent bool) map[string]int {
	var parentID func(capture, spanStream, map[string]bool) string
	if includeParent {
		parentID = spanParentRelationshipID
	}
	return workloadSpanIdentitiesWithParentID(c, ignoredResourceAttributes, identify, parentID)
}

func workloadSpanIdentitiesWithParentID(c capture, ignoredResourceAttributes map[string]bool, identify func(object) string, parentID func(capture, spanStream, map[string]bool) string) map[string]int {
	identities := map[string]int{}
	for _, stream := range workloadSpanStreams(c) {
		span := stream.Span
		if id := identify(span); id != "" {
			id += "\x00" + spanContextID(stream, ignoredResourceAttributes)
			if parentID != nil {
				id += "\x00" + parentID(c, stream, ignoredResourceAttributes)
			}
			identities[id]++
		}
	}
	return identities
}

func workloadSpanStreams(c capture) []spanStream {
	traceIDs := map[string]bool{}
	for _, stream := range captureSpanStreams(c) {
		if isProbeServerSpan(stream.Span) {
			if traceID, ok := field(stream.Span, "trace_id").(string); ok && validTrace(traceID) {
				traceIDs[traceID] = true
			}
		}
	}
	var streams []spanStream
	for _, stream := range captureSpanStreams(c) {
		traceID, _ := field(stream.Span, "trace_id").(string)
		if traceIDs[traceID] {
			streams = append(streams, stream)
		}
	}
	return streams
}

func isProbeServerSpan(span object) bool {
	if number(field(span, "kind")) != 2 {
		return false
	}
	route := attributeValue(span, "http.route")
	name, _ := field(span, "name").(string)
	return strings.Contains(route, "api/tags") || strings.Contains(route, "api/users") || strings.Contains(name, "api/tags") || strings.Contains(name, "api/users")
}

func isPropagationProbeServerSpan(span object) bool {
	userAgent := attributeValue(span, "http.user_agent")
	if userAgent == "" {
		userAgent = attributeValue(span, "user_agent.original")
	}
	taggedUserAgent := userAgent != "" && strings.HasPrefix("external-feature-probe-long-user-agent", userAgent)
	injectedParent := field(span, "parent_span_id") == "00f067aa0ba902b7"
	if number(field(span, "kind")) != 2 || (!taggedUserAgent && !injectedParent) {
		return false
	}
	route := attributeValue(span, "http.route")
	name, _ := field(span, "name").(string)
	return strings.Contains(route, "api/tags") || strings.Contains(name, "api/tags")
}

func spanParentRelationshipID(c capture, child spanStream, ignoredResourceAttributes map[string]bool) string {
	parentID, _ := field(child.Span, "parent_span_id").(string)
	if parentID == "" {
		return "root"
	}
	if !validSpan(parentID) {
		return "invalid"
	}
	traceID, _ := field(child.Span, "trace_id").(string)
	for _, candidate := range captureSpanStreams(c) {
		if field(candidate.Span, "trace_id") == traceID && field(candidate.Span, "span_id") == parentID {
			return "local\x00" + workloadSpanShapeID(candidate.Span) + "\x00" + spanContextID(candidate, ignoredResourceAttributes)
		}
	}
	if isPropagationProbeServerSpan(child.Span) {
		return "remote-probe\x00" + parentID
	}
	return "remote"
}

func spanParentRelationshipIDForPropagation(c capture, child spanStream, ignoredResourceAttributes map[string]bool) string {
	if isPropagationProbeServerSpan(child.Span) {
		return "propagation-probe"
	}
	parentID, _ := field(child.Span, "parent_span_id").(string)
	if parentID == "" {
		return "root"
	}
	if !validSpan(parentID) {
		return "invalid"
	}
	traceID, _ := field(child.Span, "trace_id").(string)
	for _, candidate := range captureSpanStreams(c) {
		if field(candidate.Span, "trace_id") == traceID && field(candidate.Span, "span_id") == parentID {
			shapeID := workloadSpanShapeID(candidate.Span)
			if isPropagationProbeServerSpan(candidate.Span) {
				normalized := make(object, len(candidate.Span))
				for key, value := range candidate.Span {
					if canonical(key) != canonical("flags") {
						normalized[key] = value
					}
				}
				shapeID = workloadSpanShapeID(normalized)
			}
			return "local\x00" + shapeID + "\x00" + spanContextID(candidate, ignoredResourceAttributes)
		}
	}
	return "remote"
}

func captureSpanStreams(c capture) []spanStream {
	if len(c.SpanStreams) > 0 {
		return c.SpanStreams
	}
	streams := make([]spanStream, 0, len(c.Spans))
	for _, span := range c.Spans {
		streams = append(streams, spanStream{Span: span})
	}
	return streams
}

func spanContextID(stream spanStream, ignoredResourceAttributes map[string]bool) string {
	scopeName, _ := field(stream.Scope, "name").(string)
	scopeVersion, _ := field(stream.Scope, "version").(string)
	parts := []string{
		scopeName, scopeVersion, stream.Schema, stream.ResourceSchema,
		containerAttributeContextID(stream.Scope, nil),
		resourceAttributeContextID(stream.Resource, ignoredResourceAttributes),
	}
	encoded, _ := json.Marshal(parts)
	return string(encoded)
}

func workloadSpanID(span object) string {
	return workloadSpanIDWithValue(span, func(value any) any {
		if text, ok := stringValue(value); ok {
			return object{"string_value": normalizeExternalStatePath(text)}
		}
		return value
	}, true, true)
}

func workloadSpanIDIgnoringEvents(span object) string {
	return workloadSpanIDWithValue(span, func(value any) any {
		if text, ok := stringValue(value); ok {
			return object{"string_value": normalizeExternalStatePath(text)}
		}
		return value
	}, false, true)
}

func workloadSpanIDIgnoringHeader(span object) string {
	normalized := make(object, len(span))
	for key, value := range span {
		normalized[key] = value
	}
	var retained []any
	for _, attribute := range attributes(span) {
		if field(attribute, "key") != "http.request.header.x_probe_feature" {
			retained = append(retained, attribute)
		}
	}
	normalized["attributes"] = retained
	return workloadSpanID(normalized)
}

func workloadSpanIDForPropagation(span object) string {
	if !isPropagationProbeServerSpan(span) {
		return workloadSpanID(span)
	}
	normalized := make(object, len(span))
	for key, value := range span {
		if canonical(key) != canonical("flags") && canonical(key) != canonical("trace_state") {
			normalized[key] = value
		}
	}
	return workloadSpanID(normalized)
}

func workloadSpanIDWithStringLimit(span object, limit int, limitEvents bool) string {
	name, _ := field(span, "name").(string)
	if name == "" {
		return ""
	}
	var values []string
	for _, attribute := range attributes(span) {
		key, _ := field(attribute, "key").(string)
		if key == "" {
			continue
		}
		value := normalizeSpanAttributeValue(key, field(attribute, "value"), func(value string) string {
			value = normalizeExternalStatePath(value)
			if key == "http.host" || key == "http.server_name" || key == "net.host.name" || key == "server.address" {
				value = normalizeEndpointPort(value)
			}
			if key == "http.url" || key == "url.full" {
				value = normalizeURLPort(value)
			}
			return value
		})
		value, _ = normalizeStringValues(value, limit)
		encoded, _ := json.Marshal([]any{key, normalizedJSONValue(value)})
		values = append(values, string(encoded))
	}
	sort.Strings(values)
	eventsID := spanEventSetIDWithValue(span, func(value any) any {
		value = mapStringValues(value, normalizeExternalStatePath)
		if limitEvents {
			value, _ = normalizeStringValues(value, limit)
		}
		return value
	})
	encoded, _ := json.Marshal([]any{
		normalizeExternalStatePath(name), number(field(span, "kind")), number(field(span, "flags")),
		spanStatusID(span), eventsID, spanLinkSetID(span, func(value any) any {
			value = mapStringValues(value, normalizeExternalStatePath)
			value, _ = normalizeStringValues(value, limit)
			return value
		}), traceStateID(span), number(field(span, "dropped_attributes_count")),
		number(field(span, "dropped_events_count")), number(field(span, "dropped_links_count")), values,
	})
	return string(encoded)
}

var volatilePortSpanAttributes = map[string]bool{
	"client.port":       true,
	"net.host.port":     true,
	"net.peer.port":     true,
	"network.peer.port": true,
	"server.port":       true,
}

func workloadSpanIDWithValue(span object, normalize func(any) any, includeEvents, includeFlags bool) string {
	name, _ := field(span, "name").(string)
	if name == "" {
		return ""
	}
	name = normalizeExternalStatePath(name)
	var values []string
	for _, attribute := range attributes(span) {
		key, _ := field(attribute, "key").(string)
		if key == "" {
			continue
		}
		value := normalizeSpanAttributeValue(key, normalize(field(attribute, "value")), func(value string) string {
			value = normalizeExternalStatePath(value)
			if key == "http.host" || key == "http.server_name" || key == "net.host.name" || key == "server.address" {
				value = normalizeEndpointPort(value)
			}
			if key == "http.url" || key == "url.full" {
				value = normalizeURLPort(value)
			}
			return value
		})
		encoded, _ := json.Marshal([]any{key, normalizedJSONValue(value)})
		values = append(values, string(encoded))
	}
	sort.Strings(values)
	eventsID := ""
	if includeEvents {
		eventsID = spanEventSetIDWithValue(span, normalize)
	}
	flags := float64(0)
	if includeFlags {
		flags = number(field(span, "flags"))
	}
	droppedEvents := number(field(span, "dropped_events_count"))
	if !includeEvents {
		droppedEvents = 0
	}
	encoded, _ := json.Marshal([]any{
		name, number(field(span, "kind")), flags, spanStatusID(span), eventsID,
		spanLinkSetID(span, normalize), traceStateID(span), number(field(span, "dropped_attributes_count")),
		droppedEvents, number(field(span, "dropped_links_count")), values,
	})
	return string(encoded)
}

func workloadSpanIDForCountLimit(span object, limit int) string {
	normalized := make(object, len(span))
	affected := len(attributes(span)) > limit || number(field(span, "dropped_attributes_count")) > 0
	for key, value := range span {
		if affected && (canonical(key) == canonical("attributes") || canonical(key) == canonical("dropped_attributes_count")) {
			continue
		}
		if canonical(key) == canonical("events") {
			spanEvents, valid := directObjectCollection(span, "events")
			if !valid {
				normalized[key] = value
				continue
			}
			var events []any
			for _, event := range spanEvents {
				eventCopy := make(object, len(event))
				eventAffected := len(attributes(event)) > limit || number(field(event, "dropped_attributes_count")) > 0
				for eventKey, eventValue := range event {
					if eventAffected && (canonical(eventKey) == canonical("attributes") || canonical(eventKey) == canonical("dropped_attributes_count")) {
						continue
					}
					eventCopy[eventKey] = eventValue
				}
				events = append(events, eventCopy)
			}
			normalized[key] = events
			continue
		}
		normalized[key] = value
	}
	return workloadSpanID(normalized)
}

func normalizeSpanAttributeValue(key string, value any, transform func(string) string) any {
	if volatilePortSpanAttributes[key] {
		if validPortAnyValue(value) {
			return object{"int_value": "<port>"}
		}
		return normalizedJSONValue(value)
	}
	return mapStringValues(value, transform)
}

func validPortAnyValue(value any) bool {
	wrapped, ok := value.(map[string]any)
	if !ok {
		return false
	}
	if nested := field(wrapped, "value"); nested != nil {
		return validPortAnyValue(nested)
	}
	port, valid := otlpNumber(field(wrapped, "int_value"))
	return valid && port >= 0 && port <= 65535 && math.Trunc(port) == port
}

func workloadSpanShapeID(span object) string {
	name, _ := field(span, "name").(string)
	if name == "" {
		return ""
	}
	encoded, _ := json.Marshal([]any{normalizeExternalStatePath(name), number(field(span, "kind")), number(field(span, "flags")), spanStatusID(span)})
	return string(encoded)
}

func spanEventSetIDWithValue(span object, normalize func(any) any) string {
	events, valid := directObjectCollection(span, "events")
	if !valid {
		encoded, _ := json.Marshal(normalizedJSONValue(field(span, "events")))
		return "invalid:" + string(encoded)
	}
	var eventIDs []string
	for _, event := range events {
		name, _ := field(event, "name").(string)
		if name == "" {
			continue
		}
		var values []string
		for _, attribute := range attributes(event) {
			key, _ := field(attribute, "key").(string)
			if key == "" {
				continue
			}
			encoded, _ := json.Marshal([]any{key, normalizedJSONValue(normalize(field(attribute, "value")))})
			values = append(values, string(encoded))
		}
		sort.Strings(values)
		eventTime, eventTimeValid := otlpTimestamp(field(event, "time_unix_nano"))
		start, startValid := otlpTimestamp(field(span, "start_time_unix_nano"))
		end, endValid := otlpTimestamp(field(span, "end_time_unix_nano"))
		insideParent := eventTimeValid && startValid && endValid && eventTime.Cmp(start) >= 0 && eventTime.Cmp(end) <= 0
		encoded, _ := json.Marshal([]any{name, eventTimeValid && eventTime.Sign() > 0, insideParent, number(field(event, "dropped_attributes_count")), values})
		eventIDs = append(eventIDs, string(encoded))
	}
	sort.Strings(eventIDs)
	encoded, _ := json.Marshal(eventIDs)
	return string(encoded)
}

func traceStateID(span object) string {
	state := field(span, "trace_state")
	if state == nil {
		return ""
	}
	text, ok := state.(string)
	if !ok {
		encoded, _ := json.Marshal(normalizedJSONValue(state))
		return "invalid:" + string(encoded)
	}
	return text
}

func spanLinkSetID(span object, normalize func(any) any) string {
	links, valid := directObjectCollection(span, "links")
	if !valid {
		encoded, _ := json.Marshal(normalizedJSONValue(field(span, "links")))
		return "invalid:" + string(encoded)
	}
	var ids []string
	for _, link := range links {
		traceID, _ := field(link, "trace_id").(string)
		spanID, _ := field(link, "span_id").(string)
		context := "invalid"
		if validTrace(traceID) && validSpan(spanID) {
			context = "valid"
			if traceID == field(span, "trace_id") {
				context = "same-trace"
			}
		}
		var values []string
		for _, attribute := range attributes(link) {
			key, _ := field(attribute, "key").(string)
			if key == "" {
				continue
			}
			value := normalizeSpanAttributeValue(key, normalize(field(attribute, "value")), normalizeExternalStatePath)
			encoded, _ := json.Marshal([]any{key, normalizedJSONValue(value)})
			values = append(values, string(encoded))
		}
		sort.Strings(values)
		encoded, _ := json.Marshal([]any{context, traceStateID(link), number(field(link, "flags")), number(field(link, "dropped_attributes_count")), values})
		ids = append(ids, string(encoded))
	}
	sort.Strings(ids)
	encoded, _ := json.Marshal(ids)
	return string(encoded)
}

func directObjectCollection(container object, name string) ([]object, bool) {
	raw := field(container, name)
	if raw == nil {
		return nil, true
	}
	items, ok := raw.([]any)
	if !ok {
		return nil, false
	}
	result := make([]object, 0, len(items))
	for _, item := range items {
		value, ok := item.(map[string]any)
		if !ok {
			return nil, false
		}
		result = append(result, value)
	}
	return result, true
}

func spanStatusID(span object) []any {
	status, _ := field(span, "status").(map[string]any)
	message, _ := field(status, "message").(string)
	return []any{number(field(status, "code")), normalizeExternalStatePath(message)}
}
func limitedProbeRequests(before, after capture, limit int) (int, int) {
	expected := incomingProbeTraces(probeSpans(before))
	present := map[string]bool{}
	for _, span := range after.Spans {
		id, _ := field(span, "trace_id").(string)
		if number(field(span, "kind")) == 2 && expected[id] && len(attributes(span)) == limit && number(field(span, "dropped_attributes_count")) > 0 {
			present[id] = true
		}
	}
	return len(expected), len(present)
}
func validTrace(id string) bool {
	decoded, err := hex.DecodeString(id)
	return err == nil && len(decoded) == 16 && id != strings.Repeat("0", 32)
}
func headerArrayStatus(s object) (bool, bool) {
	present, exact := false, false
	for _, a := range attributes(s) {
		if field(a, "key") == "http.request.header.x_probe_feature" {
			if present {
				return true, false
			}
			present = true
			arrays := objects(field(a, "value"), "array_value")
			if len(arrays) != 1 {
				continue
			}
			values, ok := field(arrays[0], "values").([]any)
			if !ok || len(values) != 1 {
				continue
			}
			value, ok := stringValue(values[0])
			exact = ok && value == "visible"
		}
	}
	return present, exact
}

func headerArray(s object) bool {
	_, exact := headerArrayStatus(s)
	return exact
}

func matchingLengthLimitedLogStreams(before, after capture, limit int) (int, int) {
	return matchingLogStreamsWithID(before, after, nil, func(stream logStream) string {
		return logLengthStreamID(stream, limit)
	}, logCorrelationID)
}

func preservedLongLogAttributes(before, after capture, limit int) (int, int, int) {
	return preservedLongIdentifiedAttributes(identifiedLogRecords(before), identifiedLogRecords(after), limit)
}

type identifiedRecord struct {
	Record object
	ID     string
}

func identifiedLogRecords(c capture) []identifiedRecord {
	groups := map[string][]object{}
	for _, stream := range captureLogStreams(c) {
		if id := logLimitStreamID(stream); id != "" {
			groups[id] = append(groups[id], stream.Record)
		}
	}
	var identified []identifiedRecord
	for stableID, records := range groups {
		sort.SliceStable(records, func(i, j int) bool {
			return fmt.Sprint(field(records[i], "time_unix_nano")) < fmt.Sprint(field(records[j], "time_unix_nano"))
		})
		for ordinal, record := range records {
			identified = append(identified, identifiedRecord{Record: record, ID: fmt.Sprintf("%s\x00%d", stableID, ordinal)})
		}
	}
	return identified
}

func preservedLongSpanAttributes(before, after capture, limit int) (int, int, int) {
	return preservedLongIdentifiedAttributes(identifiedIncomingSpans(before), identifiedIncomingSpans(after), limit)
}

func preservedLongEventAttributes(before, after capture, limit int) (int, int, int) {
	return preservedLongIdentifiedAttributes(identifiedGlobalEvents(before, func(span object) string {
		return workloadSpanIDWithStringLimit(span, limit, true)
	}), identifiedGlobalEvents(after, func(span object) string {
		return workloadSpanIDWithStringLimit(span, limit, true)
	}), limit)
}

func matchingLengthLimitedEvents(before, after capture, limit int) (int, int) {
	identities := func(c capture) map[string]int {
		items := map[string]int{}
		for _, event := range identifiedGlobalEvents(c, func(span object) string {
			return workloadSpanIDWithStringLimit(span, limit, true)
		}) {
			items[event.ID+"\x00"+attributeSetIDWithStringLimit(event.Record, limit)]++
		}
		return items
	}
	return matchingIdentityCounts(identities(before), identities(after))
}

func matchingGlobalCountLimitedEvents(before, after capture, limit int) (int, int) {
	identities := func(c capture) map[string]int {
		items := map[string]int{}
		for _, event := range identifiedGlobalEvents(c, workloadSpanShapeID) {
			attributeID := attributeSetID(event.Record, nil)
			droppedID := fmt.Sprint(number(field(event.Record, "dropped_attributes_count")))
			if len(attributes(event.Record)) > limit || number(field(event.Record, "dropped_attributes_count")) > 0 {
				attributeID = "<count-limited>"
				droppedID = "<count-limited>"
			}
			items[event.ID+"\x00"+attributeID+"\x00"+droppedID]++
		}
		return items
	}
	return matchingIdentityCounts(identities(before), identities(after))
}

func identifiedGlobalEvents(c capture, parentIdentify func(object) string) []identifiedRecord {
	groups := map[string][]object{}
	for _, stream := range captureSpanStreams(c) {
		parentID := parentIdentify(stream.Span)
		if parentID == "" {
			continue
		}
		parentID += "\x00" + spanContextID(stream, nil) + "\x00" + spanParentRelationshipID(c, stream, nil)
		for _, event := range objects(stream.Span, "events") {
			name, _ := field(event, "name").(string)
			if name != "" {
				groups[parentID+"\x00"+name] = append(groups[parentID+"\x00"+name], event)
			}
		}
	}
	var identified []identifiedRecord
	for stableID, records := range groups {
		sort.SliceStable(records, func(i, j int) bool {
			return fmt.Sprint(field(records[i], "time_unix_nano")) < fmt.Sprint(field(records[j], "time_unix_nano"))
		})
		for ordinal, record := range records {
			identified = append(identified, identifiedRecord{Record: record, ID: fmt.Sprintf("%s\x00%d", stableID, ordinal)})
		}
	}
	return identified
}

func identifiedIncomingSpans(c capture) []identifiedRecord {
	groups := map[string][]object{}
	for _, stream := range captureSpanStreams(c) {
		span := stream.Span
		traceID, _ := field(span, "trace_id").(string)
		name, _ := field(span, "name").(string)
		if !incomingTrace(traceID) || name == "" {
			continue
		}
		encoded, _ := json.Marshal([]any{traceID, normalizeExternalStatePath(name), number(field(span, "kind")), spanContextID(stream, nil)})
		groups[string(encoded)] = append(groups[string(encoded)], span)
	}
	var identified []identifiedRecord
	for stableID, spans := range groups {
		sort.SliceStable(spans, func(i, j int) bool {
			return fmt.Sprint(field(spans[i], "start_time_unix_nano")) < fmt.Sprint(field(spans[j], "start_time_unix_nano"))
		})
		for ordinal, span := range spans {
			identified = append(identified, identifiedRecord{Record: span, ID: fmt.Sprintf("%s\x00%d", stableID, ordinal)})
		}
	}
	return identified
}

func preservedLongIdentifiedAttributes(before, after []identifiedRecord, limit int) (int, int, int) {
	eligible, originals := map[string]int{}, map[string]int{}
	for _, identified := range before {
		for _, attribute := range attributes(identified.Record) {
			key, _ := field(attribute, "key").(string)
			value := field(attribute, "value")
			cappedID, valid := normalizedStringValueID(value, limit)
			if key != "" && valid && maxStringValueLength(value) > limit {
				prefix := identified.ID + "\x00" + key + "\x00"
				originalID, _ := normalizedStringValueID(value, -1)
				eligible[prefix+cappedID]++
				originals[prefix+originalID]++
			}
		}
	}
	preserved, uncapped := map[string]int{}, map[string]int{}
	for _, identified := range after {
		for _, attribute := range attributes(identified.Record) {
			key, _ := field(attribute, "key").(string)
			valueID, valid := normalizedStringValueID(field(attribute, "value"), -1)
			identity := identified.ID + "\x00" + key + "\x00" + valueID
			if valid && preserved[identity] < eligible[identity] {
				preserved[identity]++
			} else if valid && uncapped[identity] < originals[identity] {
				uncapped[identity]++
			}
		}
	}
	expected, present, retainedUncapped := countIdentities(eligible), countIdentities(preserved), countIdentities(uncapped)
	return expected, present, expected - present - retainedUncapped
}

func matchingLogRecords(before, after []object) (int, int) {
	eligible := map[string]int{}
	for _, record := range before {
		if id := logRecordIdentity(record); id != "" {
			eligible[id]++
		}
	}
	preserved := map[string]int{}
	for _, record := range after {
		if id := logRecordIdentity(record); id != "" && preserved[id] < eligible[id] {
			preserved[id]++
		}
	}
	return countIdentities(eligible), countIdentities(preserved)
}

func captureLogStreams(c capture) []logStream {
	if len(c.LogStreams) > 0 {
		return c.LogStreams
	}
	streams := make([]logStream, 0, len(c.Logs))
	for _, record := range c.Logs {
		streams = append(streams, logStream{Record: record})
	}
	return streams
}

func matchingLogStreams(before, after capture, ignoredResourceAttributes map[string]bool) (int, int) {
	return matchingLogStreamsWithID(before, after, ignoredResourceAttributes, func(stream logStream) string {
		return logStreamID(stream, ignoredResourceAttributes)
	}, logCorrelationID)
}

func matchingLogStreamsIgnoringCorrelation(before, after capture) (int, int) {
	return matchingLogStreamsWithID(before, after, nil, func(stream logStream) string {
		return logStreamID(stream, nil)
	}, nil)
}

func matchingLogStreamsForSampler(before, after capture) (int, int) {
	return matchingLogStreamsWithID(before, after, nil, func(stream logStream) string {
		return logStreamID(stream, nil)
	}, logCorrelationValidityID)
}

func matchingLogStreamsForPropagation(before, after capture) (int, int) {
	return matchingLogStreamsWithID(before, after, nil, func(stream logStream) string {
		return logStreamID(stream, nil)
	}, logCorrelationIDForPropagation)
}

func matchingLogStreamsWithID(before, after capture, ignoredResourceAttributes map[string]bool, identify func(logStream) string, correlationID func(capture, object, map[string]bool) string) (int, int) {
	identities := func(c capture) map[string]int {
		items := map[string]int{}
		for _, stream := range captureLogStreams(c) {
			id := identify(stream)
			if id == "" {
				continue
			}
			if correlationID != nil {
				encoded, _ := json.Marshal([]string{id, correlationID(c, stream.Record, ignoredResourceAttributes)})
				id = string(encoded)
			}
			items[id]++
		}
		return items
	}
	eligible := identities(before)
	return matchingIdentityCounts(eligible, identities(after))
}

func logStreamID(stream logStream, ignoredResourceAttributes map[string]bool) string {
	return logStreamIDWithRecordAttributes(stream, ignoredResourceAttributes, true, true)
}

func logLimitStreamID(stream logStream) string {
	return logStreamIDWithRecordAttributes(stream, nil, false, false)
}

func logLengthStreamID(stream logStream, limit int) string {
	recordID := stableLogRecordID(stream.Record, false)
	if recordID == "" {
		return ""
	}
	scopeName, _ := field(stream.Scope, "name").(string)
	scopeVersion, _ := field(stream.Scope, "version").(string)
	parts := []string{
		recordID, scopeName, scopeVersion, stream.Schema, stream.ResourceSchema,
		containerAttributeContextID(stream.Scope, nil),
		resourceAttributeContextID(stream.Resource, nil),
		attributeSetIDWithStringLimit(stream.Record, limit),
		fmt.Sprint(number(field(stream.Record, "dropped_attributes_count"))),
	}
	encoded, _ := json.Marshal(parts)
	return string(encoded)
}

func matchingCountLimitedLogStreams(before, after capture, limit int) (int, int) {
	return matchingLogStreamsWithID(before, after, nil, func(stream logStream) string {
		return logCountStreamID(stream, limit)
	}, logCorrelationID)
}

func logCountStreamID(stream logStream, limit int) string {
	recordID := stableLogRecordID(stream.Record, false)
	if recordID == "" {
		return ""
	}
	scopeName, _ := field(stream.Scope, "name").(string)
	scopeVersion, _ := field(stream.Scope, "version").(string)
	attributeID := attributeSetID(stream.Record, nil)
	droppedID := fmt.Sprint(number(field(stream.Record, "dropped_attributes_count")))
	if len(attributes(stream.Record)) > limit || number(field(stream.Record, "dropped_attributes_count")) > 0 {
		attributeID = "<count-limited>"
		droppedID = "<count-limited>"
	}
	parts := []string{
		recordID, scopeName, scopeVersion, stream.Schema, stream.ResourceSchema,
		containerAttributeContextID(stream.Scope, nil),
		resourceAttributeContextID(stream.Resource, nil),
		attributeID,
		droppedID,
	}
	encoded, _ := json.Marshal(parts)
	return string(encoded)
}

func logStreamIDWithRecordAttributes(stream logStream, ignoredResourceAttributes map[string]bool, includeRecordAttributes, includeDroppedAttributes bool) string {
	recordID := stableLogRecordID(stream.Record, includeRecordAttributes)
	if recordID == "" {
		return ""
	}
	scopeName, _ := field(stream.Scope, "name").(string)
	scopeVersion, _ := field(stream.Scope, "version").(string)
	parts := []string{
		recordID, scopeName, scopeVersion, stream.Schema, stream.ResourceSchema,
		containerAttributeContextID(stream.Scope, nil),
		resourceAttributeContextID(stream.Resource, ignoredResourceAttributes),
	}
	if includeDroppedAttributes {
		parts = append(parts, fmt.Sprint(number(field(stream.Record, "dropped_attributes_count"))))
	}
	encoded, _ := json.Marshal(parts)
	return string(encoded)
}

func stableLogRecordID(record object, includeAttributes bool) string {
	body := logRecordIdentity(record)
	if body == "" {
		return ""
	}
	stable := object{}
	for key, value := range record {
		switch canonical(key) {
		case "attributes", "body", "droppedattributescount", "flags", "observedtimeunixnano", "spanid", "timeunixnano", "traceid":
			continue
		default:
			stable[canonical(key)] = normalizedJSONValue(value)
		}
	}
	parts := []any{body, stable}
	parts = append(parts, logTimestampID(record))
	if includeAttributes {
		parts = append(parts, attributeSetID(record, nil))
	}
	encoded, _ := json.Marshal(parts)
	return string(encoded)
}

func logTimestampID(record object) string {
	eventTime, eventValid := otlpTimestamp(field(record, "time_unix_nano"))
	observedTime, observedValid := otlpTimestamp(field(record, "observed_time_unix_nano"))
	ordered := !eventValid || !observedValid || observedTime.Cmp(eventTime) >= 0
	encoded, _ := json.Marshal([]bool{eventValid && eventTime.Sign() > 0, observedValid && observedTime.Sign() > 0, ordered})
	return string(encoded)
}

func logCorrelationID(c capture, record object, ignoredResourceAttributes map[string]bool) string {
	traceID, _ := field(record, "trace_id").(string)
	spanID, _ := field(record, "span_id").(string)
	state, target := "none", ""
	if traceID != "" || spanID != "" {
		state = "invalid"
		if validTrace(traceID) && validSpan(spanID) {
			state = "unmatched"
			for _, stream := range captureSpanStreams(c) {
				if field(stream.Span, "trace_id") == traceID && field(stream.Span, "span_id") == spanID {
					state = "matched"
					target = workloadSpanShapeID(stream.Span) + "\x00" + spanContextID(stream, ignoredResourceAttributes)
					break
				}
			}
		}
	}
	encoded, _ := json.Marshal([]any{state, target, number(field(record, "flags"))})
	return string(encoded)
}

func logCorrelationValidityID(_ capture, record object, _ map[string]bool) string {
	traceID, _ := field(record, "trace_id").(string)
	spanID, _ := field(record, "span_id").(string)
	if traceID == "" && spanID == "" {
		return "none"
	}
	if validTrace(traceID) && validSpan(spanID) {
		return "valid"
	}
	return "invalid"
}

func logCorrelationIDForPropagation(c capture, record object, ignoredResourceAttributes map[string]bool) string {
	traceID, _ := field(record, "trace_id").(string)
	spanID, _ := field(record, "span_id").(string)
	if !validTrace(traceID) || !validSpan(spanID) {
		return logCorrelationID(c, record, ignoredResourceAttributes)
	}
	probeTrace := false
	for _, stream := range workloadSpanStreams(c) {
		if field(stream.Span, "trace_id") == traceID && isPropagationProbeServerSpan(stream.Span) {
			probeTrace = true
			break
		}
	}
	if !probeTrace {
		return logCorrelationID(c, record, ignoredResourceAttributes)
	}
	for _, stream := range captureSpanStreams(c) {
		if field(stream.Span, "trace_id") == traceID && field(stream.Span, "span_id") == spanID {
			encoded, _ := json.Marshal([]any{"probe-matched", workloadSpanIDForPropagation(stream.Span), spanContextID(stream, ignoredResourceAttributes), number(field(record, "flags"))})
			return string(encoded)
		}
	}
	encoded, _ := json.Marshal([]any{"probe-unmatched", number(field(record, "flags"))})
	return string(encoded)
}

func validSpan(id string) bool {
	decoded, err := hex.DecodeString(id)
	return err == nil && len(decoded) == 8 && id != strings.Repeat("0", 16)
}

func logRecordIdentity(record object) string {
	bodyValue := field(record, "body")
	if bodyValue == nil {
		return ""
	}
	if body, ok := stringValue(bodyValue); ok {
		if strings.HasPrefix(body, "Started ") {
			if prefix, _, found := strings.Cut(body, " at "); found {
				body = prefix
			}
		}
		if strings.HasPrefix(body, "Completed ") {
			if prefix, _, found := strings.Cut(body, " in "); found {
				body = prefix
			}
		}
		bodyValue = object{"string_value": normalizeExternalStatePath(body)}
	} else {
		bodyValue = mapStringValues(bodyValue, normalizeExternalStatePath)
	}
	encoded, err := json.Marshal(normalizedJSONValue(bodyValue))
	if err != nil {
		return ""
	}
	return string(encoded)
}

func limitedCountLogStreamRecords(before, after capture, limit int) (int, int) {
	eligible := map[string][]object{}
	for _, stream := range captureLogStreams(before) {
		if id := logLimitStreamID(stream); id != "" && len(attributes(stream.Record)) > limit {
			eligible[id] = append(eligible[id], stream.Record)
		}
	}
	preserved := map[string]int{}
	for _, stream := range captureLogStreams(after) {
		id := logLimitStreamID(stream)
		if id != "" && preserved[id] < len(eligible[id]) && len(attributes(stream.Record)) == limit {
			for index := preserved[id]; index < len(eligible[id]); index++ {
				if accurateDroppedAttributeCount(eligible[id][index], stream.Record) && attributeMultisetSubset(stream.Record, eligible[id][index]) {
					eligible[id][preserved[id]], eligible[id][index] = eligible[id][index], eligible[id][preserved[id]]
					preserved[id]++
					break
				}
			}
		}
	}
	expected, present := 0, 0
	for _, records := range eligible {
		expected += len(records)
	}
	for _, count := range preserved {
		present += count
	}
	return expected, present
}

func limitedGlobalCountSpanRecords(before, after capture, limit int) (int, int) {
	identity := func(c capture, stream spanStream) string {
		return workloadSpanIDForCountLimit(stream.Span, limit) + "\x00" + spanContextID(stream, nil) + "\x00" + spanParentRelationshipID(c, stream, nil)
	}
	eligible := map[string][]object{}
	for _, stream := range workloadSpanStreams(before) {
		if len(attributes(stream.Span)) > limit {
			id := identity(before, stream)
			eligible[id] = append(eligible[id], stream.Span)
		}
	}
	preserved := map[string]int{}
	expectedDropped := map[string]float64{}
	for _, stream := range workloadSpanStreams(after) {
		id := identity(after, stream)
		dropped := number(field(stream.Span, "dropped_attributes_count"))
		if len(attributes(stream.Span)) == limit && dropped > 0 && (expectedDropped[id] == 0 || dropped < expectedDropped[id]) {
			expectedDropped[id] = dropped
		}
	}
	for _, stream := range workloadSpanStreams(after) {
		id := identity(after, stream)
		if preserved[id] < len(eligible[id]) && len(attributes(stream.Span)) == limit {
			for index := preserved[id]; index < len(eligible[id]); index++ {
				if consistentDroppedAttributeCount(eligible[id][index], stream.Span, expectedDropped[id]) && spanAttributeMultisetSubset(stream.Span, eligible[id][index]) {
					eligible[id][preserved[id]], eligible[id][index] = eligible[id][index], eligible[id][preserved[id]]
					preserved[id]++
					break
				}
			}
		}
	}
	return countObjectGroups(eligible), countIdentities(preserved)
}

func limitedGlobalCountEventRecords(before, after capture, limit int) (int, int) {
	identifyParent := func(span object) string { return workloadSpanIDForCountLimit(span, limit) }
	eligible := map[string]object{}
	for _, event := range identifiedGlobalEvents(before, identifyParent) {
		if len(attributes(event.Record)) > limit {
			eligible[event.ID] = event.Record
		}
	}
	preserved := 0
	for _, event := range identifiedGlobalEvents(after, identifyParent) {
		if baseline := eligible[event.ID]; baseline != nil && len(attributes(event.Record)) == limit && accurateDroppedAttributeCount(baseline, event.Record) && attributeMultisetSubset(event.Record, baseline) {
			preserved++
		}
	}
	return len(eligible), preserved
}

func limitedEventRecords(before, after capture, limit int) (int, int) {
	eligible := map[string][]object{}
	for _, parent := range identifiedSpans(before) {
		for _, event := range objects(parent.Record, "events") {
			eventName, _ := field(event, "name").(string)
			if eventName != "" && len(attributes(event)) > limit {
				key := parent.ID + "\x00" + eventName
				eligible[key] = append(eligible[key], event)
			}
		}
	}
	preserved := map[string]int{}
	for _, parent := range identifiedSpans(after) {
		for _, event := range objects(parent.Record, "events") {
			eventName, _ := field(event, "name").(string)
			key := parent.ID + "\x00" + eventName
			if preserved[key] < len(eligible[key]) && len(attributes(event)) == limit {
				for index := preserved[key]; index < len(eligible[key]); index++ {
					if accurateDroppedAttributeCount(eligible[key][index], event) && attributeMultisetSubset(event, eligible[key][index]) {
						eligible[key][preserved[key]], eligible[key][index] = eligible[key][index], eligible[key][preserved[key]]
						preserved[key]++
						break
					}
				}
			}
		}
	}
	return countObjectGroups(eligible), countIdentities(preserved)
}

func matchingCountLimitedEvents(before, after capture, limit int) (int, int) {
	identities := func(c capture) map[string]int {
		items := map[string]int{}
		for _, parent := range identifiedSpans(c) {
			for _, event := range objects(parent.Record, "events") {
				name, _ := field(event, "name").(string)
				if name == "" {
					continue
				}
				attributeID := attributeSetID(event, nil)
				droppedID := fmt.Sprint(number(field(event, "dropped_attributes_count")))
				if len(attributes(event)) > limit || number(field(event, "dropped_attributes_count")) > 0 {
					attributeID = "<count-limited>"
					droppedID = "<count-limited>"
				}
				encoded, _ := json.Marshal([]string{parent.ID, name, attributeID, droppedID})
				items[string(encoded)]++
			}
		}
		return items
	}
	eligible := identities(before)
	return matchingIdentityCounts(eligible, identities(after))
}

func attributeMultisetSubset(candidate, baseline object) bool {
	return attributeMultisetSubsetWithValue(candidate, baseline, func(_ string, value any) any {
		return normalizedJSONValue(value)
	})
}

func accurateDroppedAttributeCount(baseline, candidate object) bool {
	removed := len(attributes(baseline)) - len(attributes(candidate))
	if removed <= 0 {
		return false
	}
	return number(field(candidate, "dropped_attributes_count")) == number(field(baseline, "dropped_attributes_count"))+float64(removed)
}

// SDKs count rejected setter attempts, which can exceed the number of
// baseline-visible attributes removed. Repeated equivalent workload requests
// must nevertheless agree, and the count must cover every visible removal.
func consistentDroppedAttributeCount(baseline, candidate object, expected float64) bool {
	removed := len(attributes(baseline)) - len(attributes(candidate))
	reported := number(field(candidate, "dropped_attributes_count"))
	return removed > 0 && reported == expected && reported >= number(field(baseline, "dropped_attributes_count"))+float64(removed)
}

func spanAttributeMultisetSubset(candidate, baseline object) bool {
	return attributeMultisetSubsetWithValue(candidate, baseline, func(key string, value any) any {
		return normalizedJSONValue(normalizeSpanAttributeValue(key, value, func(value string) string {
			value = normalizeExternalStatePath(value)
			if key == "http.host" || key == "http.server_name" || key == "net.host.name" || key == "server.address" {
				value = normalizeEndpointPort(value)
			}
			if key == "http.url" || key == "url.full" {
				value = normalizeURLPort(value)
			}
			return value
		}))
	})
}

func attributeMultisetSubsetWithValue(candidate, baseline object, normalize func(string, any) any) bool {
	available := map[string]int{}
	for _, attribute := range attributes(baseline) {
		key, _ := field(attribute, "key").(string)
		encoded, _ := json.Marshal([]any{key, normalize(key, field(attribute, "value"))})
		available[string(encoded)]++
	}
	for _, attribute := range attributes(candidate) {
		key, _ := field(attribute, "key").(string)
		encoded, _ := json.Marshal([]any{key, normalize(key, field(attribute, "value"))})
		id := string(encoded)
		if available[id] == 0 {
			return false
		}
		available[id]--
	}
	return true
}

func countObjectGroups(groups map[string][]object) int {
	total := 0
	for _, records := range groups {
		total += len(records)
	}
	return total
}

func identifiedSpans(c capture) []identifiedRecord {
	groups := map[string][]object{}
	for _, stream := range captureSpanStreams(c) {
		span := stream.Span
		name, _ := field(span, "name").(string)
		if name == "" {
			continue
		}
		parts := []any{name, number(field(span, "kind")), attributeSetID(span, nil), spanContextID(stream, nil)}
		encoded, _ := json.Marshal(parts)
		groups[string(encoded)] = append(groups[string(encoded)], span)
	}
	var identified []identifiedRecord
	for stableID, spans := range groups {
		sort.SliceStable(spans, func(i, j int) bool {
			return fmt.Sprint(field(spans[i], "start_time_unix_nano")) < fmt.Sprint(field(spans[j], "start_time_unix_nano"))
		})
		for ordinal, span := range spans {
			identified = append(identified, identifiedRecord{Record: span, ID: fmt.Sprintf("%s\x00%d", stableID, ordinal)})
		}
	}
	return identified
}

func suppressedEventRecords(before, after capture) (int, int) {
	eligible := map[string][]object{}
	for _, parent := range identifiedSpans(before) {
		if len(objects(parent.Record, "events")) > 0 {
			eligible[parent.ID] = append(eligible[parent.ID], parent.Record)
		}
	}
	preserved := map[string]int{}
	for _, parent := range identifiedSpans(after) {
		for _, baseline := range eligible[parent.ID][preserved[parent.ID]:] {
			removed := len(objects(baseline, "events")) - len(objects(parent.Record, "events"))
			if removed > 0 && len(objects(parent.Record, "events")) == 0 &&
				number(field(parent.Record, "dropped_events_count")) == number(field(baseline, "dropped_events_count"))+float64(removed) {
				preserved[parent.ID]++
				break
			}
		}
	}
	return countObjectGroups(eligible), countIdentities(preserved)
}

func countIdentities(items map[string]int) int {
	total := 0
	for _, count := range items {
		total += count
	}
	return total
}

func matchingIdentityCounts(eligible, actual map[string]int) (int, int) {
	expected, matched, exact := countIdentities(eligible), 0, len(eligible) == len(actual)
	for id, count := range eligible {
		actualCount := actual[id]
		if actualCount < count {
			matched += actualCount
		} else {
			matched += count
		}
		if actualCount != count {
			exact = false
		}
	}
	if !exact && matched == expected {
		return expected, expected + 1
	}
	return expected, matched
}

func captureMetricStreams(c capture) []metricStream {
	if len(c.MetricStreams) > 0 {
		return c.MetricStreams
	}
	streams := make([]metricStream, 0, len(c.Metrics))
	for _, metric := range c.Metrics {
		streams = append(streams, metricStream{Metric: metric})
	}
	return streams
}

func matchingMetricStreams(before, after capture) (int, int) {
	return matchingMetricStreamsIgnoring(before, after, nil)
}

func matchingMetricStreamsIgnoring(before, after capture, ignoredResourceAttributes map[string]bool) (int, int) {
	eligible := controlMetricIdentities(before, ignoredResourceAttributes, false, false, true)
	actual := controlMetricIdentities(after, ignoredResourceAttributes, false, true, true)
	return matchingIdentityCounts(eligible, actual)
}

func matchingMetricStreamsIgnoringExemplars(before, after capture) (int, int) {
	eligible := controlMetricIdentities(before, nil, false, false, false)
	actual := controlMetricIdentities(after, nil, false, true, false)
	return matchingIdentityCounts(eligible, actual)
}

func matchingNonHistogramMetricStreams(before, after capture) (int, int) {
	eligible := controlMetricIdentities(before, nil, true, false, true)
	actual := controlMetricIdentities(after, nil, true, true, true)
	return matchingIdentityCounts(eligible, actual)
}

func controlMetricIdentities(c capture, ignoredResourceAttributes map[string]bool, nonHistogramOnly, rejectDuplicates, includeExemplars bool) map[string]int {
	identities := map[string]int{}
	seenByGroup := map[string]bool{}
	for _, stream := range captureMetricStreams(c) {
		if nonHistogramOnly && (len(objects(stream.Metric, "histogram")) > 0 || len(objects(stream.Metric, "exponential_histogram")) > 0) {
			continue
		}
		for _, point := range objects(stream.Metric, "data_points") {
			id := controlMetricPointIDWithExemplars(stream, point, ignoredResourceAttributes, includeExemplars)
			if id == "" {
				continue
			}
			identities[id] = 1
			groupedID := fmt.Sprintf("%d\x00%s", stream.Group, id)
			if rejectDuplicates && !transientMetricPoints(stream) && seenByGroup[groupedID] {
				identities[id+"\x00duplicate"] = 1
			}
			seenByGroup[groupedID] = true
		}
	}
	return identities
}

func controlMetricPointID(stream metricStream, point object, ignoredResourceAttributes map[string]bool) string {
	return controlMetricPointIDWithExemplars(stream, point, ignoredResourceAttributes, true)
}

func controlMetricPointIDWithExemplars(stream metricStream, point object, ignoredResourceAttributes map[string]bool, includeExemplars bool) string {
	id, metricType := metricIDIgnoring(stream, ignoredResourceAttributes), metricTypeID(stream.Metric)
	if id == "" || metricType == "" {
		return ""
	}
	if transientMetricPoints(stream) {
		return fmt.Sprintf("%s\x00%s\x00%v\x00%s\x00%s", id, metricType, number(field(point, "flags")), metricMeasurementID(stream.Metric, point), metricTimestampID(point))
	}
	parts := []string{id, metricType, metricPointAttributeSetID(point), metricMeasurementID(stream.Metric, point), metricTimestampID(point)}
	if includeExemplars {
		parts = append(parts, metricExemplarSetID(point))
	}
	encoded, _ := json.Marshal(parts)
	return string(encoded)
}

func metricTimestampID(point object) string {
	end, endValid := otlpTimestamp(field(point, "time_unix_nano"))
	startValue := field(point, "start_time_unix_nano")
	start, startValid := otlpTimestamp(startValue)
	startPresent := startValid && start.Sign() > 0
	ordered := !startPresent || (endValid && end.Cmp(start) >= 0)
	encoded, _ := json.Marshal([]bool{endValid && end.Sign() > 0, startPresent, startValue == nil || startValid, ordered})
	return string(encoded)
}

// Connection states can appear and disappear between exports independently of
// the workload. Preserve this observer as a stream, but never use one of its
// momentary state points as cross-process exemplar evidence.
func transientMetricPoints(stream metricStream) bool {
	name, _ := field(stream.Metric, "name").(string)
	return name == "system.network.connections"
}

func metricID(stream metricStream) string {
	return metricIDIgnoring(stream, nil)
}

func metricIDIgnoring(stream metricStream, ignoredResourceAttributes map[string]bool) string {
	name, _ := field(stream.Metric, "name").(string)
	if name == "" {
		return ""
	}
	unit, _ := field(stream.Metric, "unit").(string)
	description, _ := field(stream.Metric, "description").(string)
	scopeName, _ := field(stream.Scope, "name").(string)
	scopeVersion, _ := field(stream.Scope, "version").(string)
	parts := []string{
		name, unit, description, scopeName, scopeVersion, stream.Schema, stream.ResourceSchema,
		containerAttributeContextID(stream.Scope, nil),
		resourceAttributeContextID(stream.Resource, ignoredResourceAttributes),
		metricMetadataID(stream.Metric),
	}
	encoded, _ := json.Marshal(parts)
	return string(encoded)
}

func metricPointID(stream metricStream, point object, ignoredResourceAttributes map[string]bool) string {
	id, metricType := metricIDIgnoring(stream, ignoredResourceAttributes), metricTypeID(stream.Metric)
	if id == "" || metricType == "" {
		return ""
	}
	return id + "\x00" + metricType + "\x00" + metricPointAttributeSetID(point)
}

func metricSeriesID(stream metricStream, point object) string {
	id := metricID(stream)
	if id == "" {
		return ""
	}
	return id + "\x00" + metricAggregationID(stream.Metric) + "\x00" + metricPointAttributeSetID(point)
}

func metricPointAttributeSetID(point object) string {
	var values []string
	for _, attribute := range attributes(point) {
		key, _ := field(attribute, "key").(string)
		if key == "" {
			continue
		}
		value := field(attribute, "value")
		if volatilePortSpanAttributes[key] {
			if validPortAnyValue(value) {
				value = object{"int_value": "<port>"}
			}
		} else if key == "http.host" || key == "http.server_name" || key == "net.host.name" || key == "server.address" {
			if endpoint, ok := stringValue(value); ok {
				value = object{"string_value": normalizeEndpointPort(endpoint)}
			}
		} else if key == "http.url" || key == "url.full" {
			if endpoint, ok := stringValue(value); ok {
				value = object{"string_value": normalizeURLPort(endpoint)}
			}
		} else if key == "pool.name" {
			if name, ok := stringValue(value); ok {
				value = object{"string_value": normalizeExternalStatePath(name)}
			}
		}
		encoded, _ := json.Marshal([]any{key, normalizedJSONValue(value)})
		values = append(values, string(encoded))
	}
	sort.Strings(values)
	encoded, _ := json.Marshal([]any{number(field(point, "flags")), values})
	return string(encoded)
}

func metricMeasurementID(metric, point object) string {
	kind := metricDataType(metric)
	valueContainer := point
	if nested, ok := field(point, "value").(map[string]any); ok {
		valueContainer = nested
	}
	_, intValid := finiteOTLPNumber(field(valueContainer, "as_int"))
	_, doubleValid := finiteOTLPNumber(field(valueContainer, "as_double"))
	if intValid && !doubleValid {
		return kind + ":int"
	}
	if doubleValid && !intValid {
		return kind + ":double"
	}
	if number(field(point, "flags")) != 0 && (kind == "gauge" || kind == "sum") {
		return kind + ":no-recorded-value"
	}
	switch kind {
	case "histogram":
		count, countValid := finiteOTLPNumber(field(point, "count"))
		total, bucketsValid, hasBuckets := bucketCountEvidence(field(point, "bucket_counts"))
		return fmt.Sprintf("histogram:count=%t:positive=%t:buckets=%t:total=%t:layout=%s:sum=%s:min=%s:max=%s", countValid, count > 0, hasBuckets && bucketsValid, !hasBuckets || total == count, histogramBucketLayoutID(point), optionalNumberState(field(point, "sum")), optionalNumberState(field(point, "min")), optionalNumberState(field(point, "max")))
	case "exponentialhistogram":
		return fmt.Sprintf("exponential-histogram:valid=%t:sum=%s:min=%s:max=%s", validExponentialHistogramPoint(point), optionalNumberState(field(point, "sum")), optionalNumberState(field(point, "min")), optionalNumberState(field(point, "max")))
	case "summary":
		count, countValid := finiteOTLPNumber(field(point, "count"))
		quantiles, quantilesValid := summaryQuantileEvidence(point)
		return fmt.Sprintf("summary:count=%t:positive=%t:sum=%s:quantiles=%d:valid=%t", countValid, count > 0, optionalNumberState(field(point, "sum")), quantiles, quantilesValid)
	default:
		return kind + ":missing"
	}
}

func histogramBucketLayoutID(point object) string {
	bounds, boundsValid := field(point, "explicit_bounds").([]any)
	counts, countsValid := field(point, "bucket_counts").([]any)
	if field(point, "explicit_bounds") == nil {
		boundsValid = true
	}
	if field(point, "bucket_counts") == nil {
		countsValid = true
	}
	encoded, _ := json.Marshal([]any{
		normalizedJSONValue(field(point, "explicit_bounds")),
		boundsValid,
		countsValid,
		len(counts),
		boundsValid && countsValid && (len(counts) == 0 || len(counts) == len(bounds)+1),
	})
	return string(encoded)
}

func finiteOTLPNumber(value any) (float64, bool) {
	number, ok := otlpNumber(value)
	return number, ok && !math.IsNaN(number) && !math.IsInf(number, 0)
}

func optionalNumberState(value any) string {
	if value == nil {
		return "absent"
	}
	_, ok := finiteOTLPNumber(value)
	if ok {
		return "valid"
	}
	return "invalid"
}

func bucketCountEvidence(value any) (float64, bool, bool) {
	if value == nil {
		return 0, true, false
	}
	values, ok := value.([]any)
	if !ok {
		return 0, false, true
	}
	total := float64(0)
	for _, value := range values {
		count, valid := finiteOTLPNumber(value)
		if !valid || count < 0 {
			return 0, false, true
		}
		total += count
	}
	return total, true, true
}

func summaryQuantileEvidence(point object) (int, bool) {
	quantiles := objects(point, "quantile_values")
	previous := float64(-1)
	for _, quantile := range quantiles {
		q, qValid := finiteOTLPNumber(field(quantile, "quantile"))
		_, valueValid := finiteOTLPNumber(field(quantile, "value"))
		if !qValid || !valueValid || q < 0 || q > 1 || q < previous {
			return len(quantiles), false
		}
		previous = q
	}
	return len(quantiles), true
}

func metricExemplarSetID(point object) string {
	unique := map[string]bool{}
	for _, exemplar := range objects(point, "exemplars") {
		timestamp, timestampValid := otlpTimestamp(field(exemplar, "time_unix_nano"))
		valueContainer := exemplar
		if nested, ok := field(exemplar, "value").(map[string]any); ok {
			valueContainer = nested
		}
		valueKind := "invalid"
		if _, ok := finiteOTLPNumber(field(valueContainer, "as_int")); ok {
			valueKind = "int"
		} else if _, ok := finiteOTLPNumber(field(valueContainer, "as_double")); ok {
			valueKind = "double"
		}
		traceID, _ := field(exemplar, "trace_id").(string)
		spanID, _ := field(exemplar, "span_id").(string)
		context := "none"
		if traceID != "" || spanID != "" {
			context = "invalid"
			if validTrace(traceID) && validSpan(spanID) {
				context = "valid"
			}
		}
		filtered := object{"attributes": field(exemplar, "filtered_attributes")}
		encoded, _ := json.Marshal([]any{timestampValid && timestamp.Sign() > 0, valueKind, context, attributeSetID(filtered, nil)})
		unique[string(encoded)] = true
	}
	var ids []string
	for id := range unique {
		ids = append(ids, id)
	}
	sort.Strings(ids)
	encoded, _ := json.Marshal(ids)
	return string(encoded)
}

func normalizeEndpointPort(value string) string {
	host, port, err := net.SplitHostPort(value)
	if err != nil || port == "" {
		return value
	}
	if _, err := strconv.ParseUint(port, 10, 16); err != nil {
		return value
	}
	return net.JoinHostPort(host, "<port>")
}

func normalizeURLPort(value string) string {
	parsed, err := url.Parse(value)
	if err != nil || parsed.Host == "" {
		return value
	}
	parsed.Host = normalizeEndpointPort(parsed.Host)
	return parsed.String()
}

func mapStringValues(value any, transform func(string) string) any {
	switch value := value.(type) {
	case map[string]any:
		normalized := make(map[string]any, len(value))
		for key, child := range value {
			if canonical(key) == canonical("string_value") {
				if text, ok := child.(string); ok {
					normalized[key] = transform(text)
					continue
				}
			}
			normalized[key] = mapStringValues(child, transform)
		}
		return normalized
	case []any:
		normalized := make([]any, len(value))
		for index, child := range value {
			normalized[index] = mapStringValues(child, transform)
		}
		return normalized
	default:
		return value
	}
}

func normalizeExternalStatePath(value string) string {
	prefix, remainder, found := strings.Cut(value, "/rules_stests/external-")
	if !found {
		return value
	}
	_, suffix, found := strings.Cut(remainder, "/state/")
	if !found {
		return value
	}
	return prefix + "/rules_stests/external-<case>/state/" + suffix
}

func containerAttributeContextID(container object, ignored map[string]bool) string {
	encoded, _ := json.Marshal([]any{attributeSetID(container, ignored), number(field(container, "dropped_attributes_count"))})
	return string(encoded)
}

func resourceAttributeContextID(container object, ignored map[string]bool) string {
	encoded, _ := json.Marshal([]any{
		attributeSetIDWithValue(container, ignored, normalizeResourceAttributeValue),
		number(field(container, "dropped_attributes_count")),
		objectCollectionSetID(container, "entity_refs"),
	})
	return string(encoded)
}

func metricMetadataID(metric object) string {
	return objectCollectionSetID(metric, "metadata")
}

func objectCollectionSetID(container object, name string) string {
	items, valid := directObjectCollection(container, name)
	if !valid {
		encoded, _ := json.Marshal(normalizedJSONValue(field(container, name)))
		return "invalid:" + string(encoded)
	}
	ids := make([]string, 0, len(items))
	for _, item := range items {
		encoded, _ := json.Marshal(normalizedJSONValue(item))
		ids = append(ids, string(encoded))
	}
	sort.Strings(ids)
	encoded, _ := json.Marshal(ids)
	return string(encoded)
}

func attributeSetID(container object, ignored map[string]bool) string {
	return attributeSetIDWithValue(container, ignored, func(_ string, value any) any {
		return normalizedJSONValue(value)
	})
}

func attributeSetIDWithValue(container object, ignored map[string]bool, normalize func(string, any) any) string {
	var values []string
	for _, attribute := range attributes(container) {
		key, _ := field(attribute, "key").(string)
		if key == "" || ignored[key] {
			continue
		}
		encoded, _ := json.Marshal([]any{key, normalize(key, field(attribute, "value"))})
		values = append(values, string(encoded))
	}
	sort.Strings(values)
	encoded, _ := json.Marshal(values)
	return string(encoded)
}

func normalizeResourceAttributeValue(key string, value any) any {
	switch key {
	case "process.pid":
		if validPositiveIntegerAnyValue(value) {
			return object{"int_value": "<positive-integer>"}
		}
	case "process.command_args":
		if validStringArrayAnyValue(value) {
			return object{"array_value": "<string-array>"}
		}
	case "service.instance.id":
		if text, ok := stringValue(value); ok && text != "" {
			return object{"string_value": "<non-empty>"}
		}
	}
	return normalizedJSONValue(value)
}

func validPositiveIntegerAnyValue(value any) bool {
	wrapper, ok := value.(map[string]any)
	if !ok {
		return false
	}
	if nested := field(wrapper, "value"); nested != nil {
		return validPositiveIntegerAnyValue(nested)
	}
	number, valid := otlpNumber(field(wrapper, "int_value"))
	return valid && number > 0 && math.Trunc(number) == number
}

func validStringArrayAnyValue(value any) bool {
	wrapper, ok := value.(map[string]any)
	if !ok {
		return false
	}
	if nested := field(wrapper, "value"); nested != nil {
		return validStringArrayAnyValue(nested)
	}
	array, ok := field(wrapper, "array_value").(map[string]any)
	if !ok {
		return false
	}
	values, ok := field(array, "values").([]any)
	if !ok || len(values) == 0 {
		return false
	}
	for _, value := range values {
		if _, ok := stringValue(value); !ok {
			return false
		}
	}
	return true
}

func attributeSetIDWithStringLimit(container object, limit int) string {
	var values []string
	for _, attribute := range attributes(container) {
		key, _ := field(attribute, "key").(string)
		if key == "" {
			continue
		}
		value, _ := normalizeStringValues(field(attribute, "value"), limit)
		encoded, _ := json.Marshal([]any{key, normalizedJSONValue(value)})
		values = append(values, string(encoded))
	}
	sort.Strings(values)
	encoded, _ := json.Marshal(values)
	return string(encoded)
}

func normalizedJSONValue(value any) any {
	switch value := value.(type) {
	case map[string]any:
		if len(value) == 1 {
			for key, child := range value {
				if canonical(key) == "value" {
					return normalizedJSONValue(child)
				}
			}
		}
		normalized := make(map[string]any, len(value))
		for key, child := range value {
			normalized[canonical(key)] = normalizedJSONValue(child)
		}
		return normalized
	case []any:
		normalized := make([]any, len(value))
		for index, child := range value {
			normalized[index] = normalizedJSONValue(child)
		}
		return normalized
	default:
		return value
	}
}

func metricDataType(metric object) string {
	for _, kind := range []string{"gauge", "sum", "histogram", "exponential_histogram", "summary"} {
		if len(objects(metric, kind)) > 0 {
			return canonical(kind)
		}
	}
	return ""
}

func metricTypeID(metric object) string {
	kind := metricDataType(metric)
	if kind == "" {
		return ""
	}
	encoded, _ := json.Marshal([]any{kind, metricAggregationID(metric)})
	return string(encoded)
}

func metricAggregationID(metric object) string {
	kind := metricDataType(metric)
	data := objects(metric, kind)
	if len(data) == 0 {
		return ""
	}
	monotonic, _ := field(data[0], "is_monotonic").(bool)
	encoded, _ := json.Marshal([]any{number(field(data[0], "aggregation_temporality")), monotonic})
	return string(encoded)
}

func suppressedExemplars(before, after capture) (int, int, int) {
	eligible := map[string]bool{}
	for _, stream := range captureMetricStreams(before) {
		if transientMetricPoints(stream) {
			continue
		}
		for _, point := range objects(stream.Metric, "data_points") {
			if id := metricPointID(stream, point, nil); id != "" && len(objects(point, "exemplars")) > 0 {
				eligible[id] = true
			}
		}
	}
	preserved := map[string]bool{}
	remaining := 0
	for _, stream := range captureMetricStreams(after) {
		for _, point := range objects(stream.Metric, "data_points") {
			remaining += len(objects(point, "exemplars"))
			id := metricPointID(stream, point, nil)
			if eligible[id] {
				preserved[id] = true
			}
		}
	}
	return len(eligible), len(preserved), remaining
}

func convertedHistograms(before, after capture) (int, int) {
	eligible := map[string]float64{}
	for _, stream := range captureMetricStreams(before) {
		if len(objects(stream.Metric, "histogram")) == 0 {
			continue
		}
		for _, point := range objects(stream.Metric, "data_points") {
			id := metricSeriesID(stream, point)
			count, valid := otlpNumber(field(point, "count"))
			if id != "" && valid && count > eligible[id] {
				eligible[id] = count
			}
		}
	}
	converted := map[string]float64{}
	invalid := false
	for _, stream := range captureMetricStreams(after) {
		if len(objects(stream.Metric, "exponential_histogram")) == 0 {
			continue
		}
		for _, point := range objects(stream.Metric, "data_points") {
			id := metricSeriesID(stream, point)
			count, _ := otlpNumber(field(point, "count"))
			if id == "" || !validExponentialHistogramPoint(point) {
				invalid = true
				continue
			}
			if count > converted[id] {
				converted[id] = count
			}
		}
	}
	matched, exact := 0, len(eligible) == len(converted) && !invalid
	for id, count := range eligible {
		if converted[id] == count {
			matched++
		} else {
			exact = false
		}
	}
	if !exact && matched == len(eligible) {
		return len(eligible), len(eligible) + 1
	}
	return len(eligible), matched
}

func validExponentialHistogramPoint(point object) bool {
	count, ok := otlpNumber(field(point, "count"))
	if !ok || count <= 0 || math.Trunc(count) != count {
		return false
	}
	scale := number(field(point, "scale"))
	if math.Trunc(scale) != scale || scale < -10 || scale > 20 {
		return false
	}
	if thresholdValue := field(point, "zero_threshold"); thresholdValue != nil {
		threshold, valid := finiteOTLPNumber(thresholdValue)
		if !valid || threshold < 0 {
			return false
		}
	}
	minimum, minimumValid := optionalFiniteNumber(field(point, "min"))
	maximum, maximumValid := optionalFiniteNumber(field(point, "max"))
	if !minimumValid || !maximumValid || (field(point, "min") != nil && field(point, "max") != nil && minimum > maximum) {
		return false
	}
	total, evidence := float64(0), false
	if zeroCount := field(point, "zero_count"); zeroCount != nil {
		value, valid := otlpNumber(zeroCount)
		if !valid || value < 0 || math.Trunc(value) != value {
			return false
		}
		total += value
		evidence = true
	}
	for _, side := range []string{"positive", "negative"} {
		buckets, _ := field(point, side).(map[string]any)
		values, _ := field(buckets, "bucket_counts").([]any)
		if len(values) > 0 {
			evidence = true
		}
		for _, value := range values {
			bucketCount, valid := otlpNumber(value)
			if !valid || bucketCount < 0 || math.Trunc(bucketCount) != bucketCount {
				return false
			}
			total += bucketCount
		}
	}
	return evidence && total == count
}

func optionalFiniteNumber(value any) (float64, bool) {
	if value == nil {
		return 0, true
	}
	return finiteOTLPNumber(value)
}

func otlpNumber(value any) (float64, bool) {
	switch value := value.(type) {
	case float64:
		return value, true
	case json.Number:
		number, err := strconv.ParseFloat(string(value), 64)
		return number, err == nil
	case string:
		number, err := strconv.ParseFloat(value, 64)
		return number, err == nil
	default:
		return 0, false
	}
}

func otlpTimestamp(value any) (*big.Int, bool) {
	switch value := value.(type) {
	case json.Number:
		timestamp, valid := new(big.Int).SetString(string(value), 10)
		return timestamp, valid && timestamp.Sign() >= 0
	case string:
		timestamp, valid := new(big.Int).SetString(value, 10)
		return timestamp, valid && timestamp.Sign() >= 0
	case float64:
		if math.IsNaN(value) || math.IsInf(value, 0) || value < 0 || math.Trunc(value) != value || value > 9007199254740991 {
			return nil, false
		}
		return big.NewInt(int64(value)), true
	default:
		return nil, false
	}
}

// Active-request metrics may record against a sampled remote parent before
// the server creates its nonrecording span. Exclude such metric names from
// both sides instead of mistaking their TraceBased exemplars for AlwaysOn.
func unsampledExemplars(before, after capture) (int, int, int) {
	eligible := map[string]bool{}
	excluded := map[string]bool{}
	for _, stream := range captureMetricStreams(before) {
		if transientMetricPoints(stream) {
			continue
		}
		baseID, metricType := metricID(stream), metricTypeID(stream.Metric)
		streamID := baseID + "\x00" + metricType
		if baseID != "" && metricType != "" && len(objects(stream.Metric, "exemplars")) > 0 {
			excluded[streamID] = true
		}
	}
	for _, stream := range captureMetricStreams(before) {
		if transientMetricPoints(stream) {
			continue
		}
		streamID := metricID(stream) + "\x00" + metricTypeID(stream.Metric)
		if excluded[streamID] {
			continue
		}
		for _, point := range objects(stream.Metric, "data_points") {
			if id := metricPointID(stream, point, nil); id != "" {
				eligible[id] = true
			}
		}
	}
	preserved := map[string]bool{}
	count := 0
	for _, stream := range captureMetricStreams(after) {
		for _, point := range objects(stream.Metric, "data_points") {
			id := metricPointID(stream, point, nil)
			exemplars, valid := validExemplarCount(point)
			if eligible[id] && valid && exemplars > 0 {
				preserved[id] = true
				count += exemplars
			}
		}
	}
	return len(eligible), len(preserved), count
}

func validExemplarCount(point object) (int, bool) {
	exemplars := objects(point, "exemplars")
	for _, exemplar := range exemplars {
		timestamp, timestampValid := otlpTimestamp(field(exemplar, "time_unix_nano"))
		value, _ := field(exemplar, "value").(map[string]any)
		_, intValid := otlpNumber(field(value, "as_int"))
		_, doubleValid := otlpNumber(field(value, "as_double"))
		traceValue, spanValue := field(exemplar, "trace_id"), field(exemplar, "span_id")
		traceID, traceString := traceValue.(string)
		spanID, spanString := spanValue.(string)
		contextValid := traceValue == nil && spanValue == nil
		if traceString && spanString {
			contextValid = (traceID == "" && spanID == "") || (validTrace(traceID) && validSpan(spanID))
		}
		if !timestampValid || timestamp.Sign() <= 0 || (!intValid && !doubleValid) || !contextValid {
			return 0, false
		}
	}
	return len(exemplars), true
}
