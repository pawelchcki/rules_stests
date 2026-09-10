package main

import (
	"encoding/hex"
	"encoding/json"
	"fmt"
	"net"
	"net/url"
	"sort"
	"strings"
	"unicode/utf8"
)

type object = map[string]any
type metricStream struct {
	Metric                 object
	Resource, Scope        object
	ResourceSchema, Schema string
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
	if err := json.Unmarshal(data, &records); err != nil {
		return capture{}, err
	}
	c := capture{Records: records}
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
	for _, resourceMetrics := range objects(payload, "resource_metrics") {
		resource, _ := field(resourceMetrics, "resource").(map[string]any)
		resourceSchema, _ := field(resourceMetrics, "schema_url").(string)
		for _, scopeMetrics := range objects(resourceMetrics, "scope_metrics") {
			scope, _ := field(scopeMetrics, "scope").(map[string]any)
			schema, _ := field(scopeMetrics, "schema_url").(string)
			for _, metric := range objects(scopeMetrics, "metrics") {
				streams = append(streams, metricStream{Metric: metric, Resource: resource, Scope: scope, ResourceSchema: resourceSchema, Schema: schema})
			}
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
	if n, ok := v.(float64); ok {
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
		expectedMetrics, presentMetrics := matchingMetricStreams(baseline, changed)
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
		expectedSpans, presentSpans := matchingWorkloadSpans(baseline, changed)
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
		expectedSpans, presentSpans := matchingWorkloadSpans(baseline, changed)
		expectedMetrics, presentMetrics := matchingMetricStreams(baseline, changed)
		expectedLogs, presentLogs := matchingLogStreams(baseline, changed, nil)
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
			ok = ok && attributeValue(r, "probe.external") == "visible" && attributeValue(r, "service.name") == "external-probe"
		}
		check(len(baseline.Resources) > 0, ok && preserved, fmt.Sprintf("%d resources must retain probe.external=visible and OTEL_SERVICE_NAME precedence; workload requests preserved %d/%d", len(changed.Resources), present, expected))
	case "disabled":
		check(len(baseline.Spans) > 0, len(changed.Records) == 0, fmt.Sprintf("export requests %d -> %d", len(baseline.Records), len(changed.Records)))
	case "sampler", "sampler-arg":
		expectedMetrics, presentMetrics := matchingMetricStreams(baseline, changed)
		expectedLogs, presentLogs := matchingLogStreamsIgnoringCorrelation(baseline, changed)
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
			expected, present = matchingLengthLimitedWorkloadSpans(baseline, changed, 8)
			attributeExpected, attributePresent, attributeMissing = preservedLongSpanAttributes(baseline, changed, 8)
			expectedMetrics, presentMetrics := matchingMetricStreams(baseline, changed)
			expectedLogs, presentLogs := matchingLogStreams(baseline, changed, nil)
			if e.Name == "attribute-length" {
				expectedLogs, presentLogs = matchingLengthLimitedLogStreams(baseline, changed, 8)
			}
			preserved = len(expectedTraces) == 4 && len(presentTraces) == len(expectedTraces) && expected > 0 && present == expected && attributeExpected > 0 && attributePresent == attributeExpected && presentMetrics == expectedMetrics && presentLogs == expectedLogs
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
		}
		expectedSpans, presentSpans := matchingWorkloadSpans(baseline, changed)
		if e.Name == "attribute-count" {
			expectedSpans, presentSpans = matchingCountLimitedWorkloadSpans(baseline, changed)
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
		check(prerequisite, len(after) > 0 && maxAttributes(after) == cap && dropped(after, "dropped_attributes_count") > 0 && preserved, fmt.Sprintf("maximum attributes %d -> %d; cap %d; dropped %d; affected records %d/%d; workload spans %d/%d, metrics %d/%d, logs %d/%d preserved", maxAttributes(before), maxAttributes(after), cap, dropped(after, "dropped_attributes_count"), present, expected, presentSpans, expectedSpans, presentMetrics, expectedMetrics, presentLogs, expectedLogs))
	case "events":
		expected, present := suppressedEventRecords(baseline, changed)
		expectedSpans, presentSpans := matchingWorkloadSpans(baseline, changed)
		expectedMetrics, presentMetrics := matchingMetricStreams(baseline, changed)
		expectedLogs, presentLogs := matchingLogStreams(baseline, changed, nil)
		preserved := (expected == 0 || present == expected) && presentSpans == expectedSpans && presentMetrics == expectedMetrics && presentLogs == expectedLogs
		check(len(events(baseline)) > 0, len(changed.Spans) > 0 && len(events(changed)) == 0 && dropped(changed.Spans, "dropped_events_count") > 0 && preserved, fmt.Sprintf("events %d -> %d; dropped %d; workload requests preserved %d/%d", len(events(baseline)), len(events(changed)), dropped(changed.Spans, "dropped_events_count"), present, expected))
	case "exemplars":
		before, preserved, remaining := suppressedExemplars(baseline, changed)
		expectedMetrics, presentMetrics := matchingMetricStreams(baseline, changed)
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
	return matchingWorkloadSpansWithID(before, after, ignoredResourceAttributes, workloadSpanID)
}

func matchingLengthLimitedWorkloadSpans(before, after capture, limit int) (int, int) {
	return matchingWorkloadSpansWithID(before, after, nil, func(span object) string {
		return workloadSpanIDWithStringLimit(span, limit)
	})
}

func matchingCountLimitedWorkloadSpans(before, after capture) (int, int) {
	return matchingWorkloadSpansWithID(before, after, nil, workloadSpanShapeID)
}

func matchingWorkloadSpansWithID(before, after capture, ignoredResourceAttributes map[string]bool, identify func(object) string) (int, int) {
	eligible := workloadSpanIdentitiesWithID(before, ignoredResourceAttributes, identify)
	preserved := map[string]int{}
	for id, count := range workloadSpanIdentitiesWithID(after, ignoredResourceAttributes, identify) {
		if count > eligible[id] {
			count = eligible[id]
		}
		preserved[id] = count
	}
	return countIdentities(eligible), countIdentities(preserved)
}

func workloadSpanIdentities(c capture, ignoredResourceAttributes map[string]bool) map[string]int {
	return workloadSpanIdentitiesWithID(c, ignoredResourceAttributes, workloadSpanID)
}

func workloadSpanIdentitiesWithID(c capture, ignoredResourceAttributes map[string]bool, identify func(object) string) map[string]int {
	traceIDs := map[string]bool{}
	for _, stream := range captureSpanStreams(c) {
		span := stream.Span
		if number(field(span, "kind")) != 2 {
			continue
		}
		route := attributeValue(span, "http.route")
		name, _ := field(span, "name").(string)
		if strings.Contains(route, "api/tags") || strings.Contains(route, "api/users") || strings.Contains(name, "api/tags") || strings.Contains(name, "api/users") {
			if traceID, ok := field(span, "trace_id").(string); ok && traceID != "" {
				traceIDs[traceID] = true
			}
		}
	}
	identities := map[string]int{}
	for _, stream := range captureSpanStreams(c) {
		span := stream.Span
		traceID, _ := field(span, "trace_id").(string)
		if traceIDs[traceID] {
			if id := identify(span); id != "" {
				id += "\x00" + spanContextID(stream, ignoredResourceAttributes)
				identities[id]++
			}
		}
	}
	return identities
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
		attributeSetID(stream.Scope, nil),
		attributeSetID(stream.Resource, resourceAttributeIgnores(ignoredResourceAttributes)),
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
	})
}

func workloadSpanIDWithStringLimit(span object, limit int) string {
	name, _ := field(span, "name").(string)
	if name == "" {
		return ""
	}
	var values []string
	for _, attribute := range attributes(span) {
		key, _ := field(attribute, "key").(string)
		if key == "" || lengthLimitedSpanAttributeIgnores[key] {
			continue
		}
		value := mapStringValues(field(attribute, "value"), func(value string) string {
			value = normalizeExternalStatePath(value)
			if key == "http.host" || key == "net.host.name" || key == "server.address" {
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
	encoded, _ := json.Marshal([]any{normalizeExternalStatePath(name), number(field(span, "kind")), values})
	return string(encoded)
}

var lengthLimitedSpanAttributeIgnores = map[string]bool{
	"client.port":       true,
	"net.host.port":     true,
	"net.peer.port":     true,
	"network.peer.port": true,
	"server.port":       true,
}

func workloadSpanIDWithValue(span object, normalize func(any) any) string {
	name, _ := field(span, "name").(string)
	if name == "" {
		return ""
	}
	name = normalizeExternalStatePath(name)
	stableKeys := map[string]bool{
		"db.name": true, "db.namespace": true, "db.operation": true, "db.operation.name": true,
		"db.query.text": true, "db.sql.table": true, "db.statement": true, "db.system": true, "db.system.name": true,
		"http.method": true, "http.request.method": true, "http.response.status_code": true,
		"http.route": true, "http.status_code": true, "http.target": true,
		"url.path": true, "user_agent.original": true, "http.user_agent": true,
	}
	var values []string
	for _, attribute := range attributes(span) {
		key, _ := field(attribute, "key").(string)
		if !stableKeys[key] {
			continue
		}
		value := normalize(field(attribute, "value"))
		encoded, _ := json.Marshal([]any{key, normalizedJSONValue(value)})
		values = append(values, string(encoded))
	}
	sort.Strings(values)
	encoded, _ := json.Marshal([]any{name, number(field(span, "kind")), values})
	return string(encoded)
}

func workloadSpanShapeID(span object) string {
	name, _ := field(span, "name").(string)
	if name == "" {
		return ""
	}
	encoded, _ := json.Marshal([]any{normalizeExternalStatePath(name), number(field(span, "kind"))})
	return string(encoded)
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
	}, true)
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
	}, true)
}

func matchingLogStreamsIgnoringCorrelation(before, after capture) (int, int) {
	return matchingLogStreamsWithID(before, after, nil, func(stream logStream) string {
		return logStreamID(stream, nil)
	}, false)
}

func matchingLogStreamsWithID(before, after capture, ignoredResourceAttributes map[string]bool, identify func(logStream) string, includeCorrelation bool) (int, int) {
	identities := func(c capture) map[string]int {
		items := map[string]int{}
		for _, stream := range captureLogStreams(c) {
			id := identify(stream)
			if id == "" {
				continue
			}
			if includeCorrelation {
				encoded, _ := json.Marshal([]string{id, logCorrelationID(c, stream.Record, ignoredResourceAttributes)})
				id = string(encoded)
			}
			items[id]++
		}
		return items
	}
	eligible := identities(before)
	preserved := map[string]int{}
	for id, count := range identities(after) {
		if count > eligible[id] {
			count = eligible[id]
		}
		preserved[id] = count
	}
	return countIdentities(eligible), countIdentities(preserved)
}

func logStreamID(stream logStream, ignoredResourceAttributes map[string]bool) string {
	return logStreamIDWithRecordAttributes(stream, ignoredResourceAttributes, true)
}

func logLimitStreamID(stream logStream) string {
	return logStreamIDWithRecordAttributes(stream, nil, false)
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
		attributeSetID(stream.Scope, nil),
		attributeSetID(stream.Resource, resourceAttributeIgnores(nil)),
		attributeSetIDWithStringLimit(stream.Record, limit),
	}
	encoded, _ := json.Marshal(parts)
	return string(encoded)
}

func matchingCountLimitedLogStreams(before, after capture, limit int) (int, int) {
	return matchingLogStreamsWithID(before, after, nil, func(stream logStream) string {
		return logCountStreamID(stream, limit)
	}, true)
}

func logCountStreamID(stream logStream, limit int) string {
	recordID := stableLogRecordID(stream.Record, false)
	if recordID == "" {
		return ""
	}
	scopeName, _ := field(stream.Scope, "name").(string)
	scopeVersion, _ := field(stream.Scope, "version").(string)
	attributeID := attributeSetID(stream.Record, nil)
	if len(attributes(stream.Record)) > limit || number(field(stream.Record, "dropped_attributes_count")) > 0 {
		attributeID = "<count-limited>"
	}
	parts := []string{
		recordID, scopeName, scopeVersion, stream.Schema, stream.ResourceSchema,
		attributeSetID(stream.Scope, nil),
		attributeSetID(stream.Resource, resourceAttributeIgnores(nil)),
		attributeID,
	}
	encoded, _ := json.Marshal(parts)
	return string(encoded)
}

func logStreamIDWithRecordAttributes(stream logStream, ignoredResourceAttributes map[string]bool, includeRecordAttributes bool) string {
	recordID := stableLogRecordID(stream.Record, includeRecordAttributes)
	if recordID == "" {
		return ""
	}
	scopeName, _ := field(stream.Scope, "name").(string)
	scopeVersion, _ := field(stream.Scope, "version").(string)
	parts := []string{
		recordID, scopeName, scopeVersion, stream.Schema, stream.ResourceSchema,
		attributeSetID(stream.Scope, nil),
		attributeSetID(stream.Resource, resourceAttributeIgnores(ignoredResourceAttributes)),
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
	if includeAttributes {
		parts = append(parts, attributeSetID(record, nil))
	}
	encoded, _ := json.Marshal(parts)
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

func validSpan(id string) bool {
	decoded, err := hex.DecodeString(id)
	return err == nil && len(decoded) == 8 && id != strings.Repeat("0", 16)
}

func logRecordIdentity(record object) string {
	body, ok := stringValue(field(record, "body"))
	if !ok || body == "" {
		return ""
	}
	if strings.HasPrefix(body, "Started ") {
		if prefix, _, ok := strings.Cut(body, " at "); ok {
			return prefix
		}
	}
	if strings.HasPrefix(body, "Completed ") {
		if prefix, _, ok := strings.Cut(body, " in "); ok {
			return prefix
		}
	}
	return body
}

func limitedCountLogStreamRecords(before, after capture, limit int) (int, int) {
	eligible := map[string]int{}
	for _, stream := range captureLogStreams(before) {
		if id := logLimitStreamID(stream); id != "" && len(attributes(stream.Record)) > limit {
			eligible[id]++
		}
	}
	preserved := map[string]int{}
	for _, stream := range captureLogStreams(after) {
		id := logLimitStreamID(stream)
		if id != "" && preserved[id] < eligible[id] && len(attributes(stream.Record)) == limit && number(field(stream.Record, "dropped_attributes_count")) > 0 {
			preserved[id]++
		}
	}
	expected, present := 0, 0
	for _, count := range eligible {
		expected += count
	}
	for _, count := range preserved {
		present += count
	}
	return expected, present
}

func limitedEventRecords(before, after capture, limit int) (int, int) {
	eligible := map[string]int{}
	for _, parent := range identifiedSpans(before) {
		for _, event := range objects(parent.Record, "events") {
			eventName, _ := field(event, "name").(string)
			if eventName != "" && len(attributes(event)) > limit {
				eligible[parent.ID+"\x00"+eventName]++
			}
		}
	}
	preserved := map[string]int{}
	for _, parent := range identifiedSpans(after) {
		for _, event := range objects(parent.Record, "events") {
			eventName, _ := field(event, "name").(string)
			key := parent.ID + "\x00" + eventName
			if preserved[key] < eligible[key] && len(attributes(event)) == limit && number(field(event, "dropped_attributes_count")) > 0 {
				preserved[key]++
			}
		}
	}
	return countIdentities(eligible), countIdentities(preserved)
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
				if len(attributes(event)) > limit || number(field(event, "dropped_attributes_count")) > 0 {
					attributeID = "<count-limited>"
				}
				encoded, _ := json.Marshal([]string{parent.ID, name, attributeID})
				items[string(encoded)]++
			}
		}
		return items
	}
	eligible := identities(before)
	preserved := map[string]int{}
	for id, count := range identities(after) {
		if count > eligible[id] {
			count = eligible[id]
		}
		preserved[id] = count
	}
	return countIdentities(eligible), countIdentities(preserved)
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
	eligible := map[string]int{}
	for _, parent := range identifiedSpans(before) {
		if len(objects(parent.Record, "events")) > 0 {
			eligible[parent.ID]++
		}
	}
	preserved := map[string]int{}
	for _, parent := range identifiedSpans(after) {
		if preserved[parent.ID] < eligible[parent.ID] && len(objects(parent.Record, "events")) == 0 && number(field(parent.Record, "dropped_events_count")) > 0 {
			preserved[parent.ID]++
		}
	}
	return countIdentities(eligible), countIdentities(preserved)
}

func countIdentities(items map[string]int) int {
	total := 0
	for _, count := range items {
		total += count
	}
	return total
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
	eligible := map[string]bool{}
	for _, stream := range captureMetricStreams(before) {
		for _, point := range objects(stream.Metric, "data_points") {
			if id := controlMetricPointID(stream, point, ignoredResourceAttributes); id != "" {
				eligible[id] = true
			}
		}
	}
	preserved := map[string]bool{}
	for _, stream := range captureMetricStreams(after) {
		for _, point := range objects(stream.Metric, "data_points") {
			id := controlMetricPointID(stream, point, ignoredResourceAttributes)
			if eligible[id] {
				preserved[id] = true
			}
		}
	}
	return len(eligible), len(preserved)
}

func matchingNonHistogramMetricStreams(before, after capture) (int, int) {
	eligible := map[string]bool{}
	for _, stream := range captureMetricStreams(before) {
		if len(objects(stream.Metric, "histogram")) > 0 {
			continue
		}
		for _, point := range objects(stream.Metric, "data_points") {
			if id := controlMetricPointID(stream, point, nil); id != "" {
				eligible[id] = true
			}
		}
	}
	preserved := map[string]bool{}
	for _, stream := range captureMetricStreams(after) {
		for _, point := range objects(stream.Metric, "data_points") {
			if id := controlMetricPointID(stream, point, nil); eligible[id] {
				preserved[id] = true
			}
		}
	}
	return len(eligible), len(preserved)
}

func controlMetricPointID(stream metricStream, point object, ignoredResourceAttributes map[string]bool) string {
	id, metricType := metricIDIgnoring(stream, ignoredResourceAttributes), metricTypeID(stream.Metric)
	if id == "" || metricType == "" {
		return ""
	}
	if transientMetricPoints(stream) {
		return id + "\x00" + metricType
	}
	return id + "\x00" + metricType + "\x00" + metricPointAttributeSetID(point)
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
		attributeSetID(stream.Scope, nil),
		attributeSetID(stream.Resource, resourceAttributeIgnores(ignoredResourceAttributes)),
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

var metricPointAttributeIgnores = map[string]bool{
	"client.port":       true,
	"http.server_name":  true,
	"net.host.port":     true,
	"net.peer.port":     true,
	"network.peer.port": true,
	"server.port":       true,
}

func metricPointAttributeSetID(point object) string {
	var values []string
	for _, attribute := range attributes(point) {
		key, _ := field(attribute, "key").(string)
		if key == "" || metricPointAttributeIgnores[key] {
			continue
		}
		value := field(attribute, "value")
		if key == "http.host" || key == "net.host.name" {
			if endpoint, ok := stringValue(value); ok {
				value = object{"string_value": normalizeEndpointPort(endpoint)}
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
	encoded, _ := json.Marshal(values)
	return string(encoded)
}

func normalizeEndpointPort(value string) string {
	host, port, err := net.SplitHostPort(value)
	if err != nil || port == "" {
		return value
	}
	for _, digit := range port {
		if digit < '0' || digit > '9' {
			return value
		}
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

func resourceAttributeIgnores(additional map[string]bool) map[string]bool {
	ignored := map[string]bool{
		"process.command_args": true,
		"process.pid":          true,
		"service.instance.id":  true,
	}
	for key := range additional {
		ignored[key] = true
	}
	return ignored
}

func attributeSetID(container object, ignored map[string]bool) string {
	var values []string
	for _, attribute := range attributes(container) {
		key, _ := field(attribute, "key").(string)
		if key == "" || ignored[key] {
			continue
		}
		encoded, _ := json.Marshal([]any{key, normalizedJSONValue(field(attribute, "value"))})
		values = append(values, string(encoded))
	}
	sort.Strings(values)
	encoded, _ := json.Marshal(values)
	return string(encoded)
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
	eligible := map[string]bool{}
	for _, stream := range captureMetricStreams(before) {
		if len(objects(stream.Metric, "histogram")) == 0 {
			continue
		}
		for _, point := range objects(stream.Metric, "data_points") {
			if id := metricSeriesID(stream, point); id != "" {
				eligible[id] = true
			}
		}
	}
	converted := map[string]bool{}
	for _, stream := range captureMetricStreams(after) {
		if len(objects(stream.Metric, "exponential_histogram")) == 0 {
			continue
		}
		for _, point := range objects(stream.Metric, "data_points") {
			id := metricSeriesID(stream, point)
			if eligible[id] {
				converted[id] = true
			}
		}
	}
	return len(eligible), len(converted)
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
			exemplars := len(objects(point, "exemplars"))
			if eligible[id] && exemplars > 0 {
				preserved[id] = true
				count += exemplars
			}
		}
	}
	return len(eligible), len(preserved), count
}
