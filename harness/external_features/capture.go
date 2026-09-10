package main

import (
	"encoding/hex"
	"encoding/json"
	"fmt"
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
type capture struct {
	Records                         []object
	Spans, Logs, Metrics, Resources []object
	MetricStreams                   []metricStream
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
			c.Spans = append(c.Spans, objects(p, "spans")...)
		case "logs":
			c.Logs = append(c.Logs, objects(p, "log_records")...)
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
		preserved := (len(baseline.Spans) == 0 || len(changed.Spans) > 0) &&
			(len(baseline.Logs) == 0 || len(changed.Logs) > 0) &&
			(len(baseline.Metrics) == 0 || len(changed.Metrics) > 0) &&
			(len(beforeProbes) == 0 || (len(afterProbes) == len(beforeProbes) && presentRequests == expectedRequests))
		violations := map[string]bool{}
		for _, r := range changed.Resources {
			name, present, valid := stringAttribute(r, "service.name")
			ok = ok && valid && (name == "unknown_service" || (strings.HasPrefix(name, "unknown_service:") && len(name) > len("unknown_service:")))
			if !valid || name == "" {
				kind := "malformed"
				if !present {
					kind = "missing"
				} else if valid {
					kind = "empty"
				}
				violations["service.name="+kind] = true
			}
		}
		if len(baseline.Spans) > 0 && len(changed.Spans) == 0 {
			violations["spans-missing"] = true
		}
		if len(baseline.Logs) > 0 && len(changed.Logs) == 0 {
			violations["logs-missing"] = true
		}
		if len(baseline.Metrics) > 0 && len(changed.Metrics) == 0 {
			violations["metrics-missing"] = true
		}
		if len(beforeProbes) > 0 && len(afterProbes) != len(beforeProbes) {
			violations[fmt.Sprintf("probe-spans=%d", len(afterProbes))] = true
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
			preserved = len(probes) == 4 && len(incomingProbeTraces(probes)) == 4
		} else {
			expected, present := matchingLogRecords(before, after)
			preserved = preserved && expected > 0 && present == expected
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
		check(eligible > 0 && len(baseline.Spans) == 0, len(changed.Spans) == 0 && preserved == eligible && after > 0, fmt.Sprintf("control metric streams preserved %d/%d; AlwaysOn exemplars for those streams %d; exported spans %d", preserved, eligible, after, len(changed.Spans)))
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
		check(len(before) == 4 && len(beforeRequests) == 4, len(after) == 4 && len(afterRequests) == 4 && captured == 4, fmt.Sprintf("distinct probe requests %d -> %d; server spans %d -> %d; exact header arrays %d/4", len(beforeRequests), len(afterRequests), len(before), len(after), captured))
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
		check(len(before) == 4 && len(continued) == 4, len(after) == 4 && len(roots) == 4, fmt.Sprintf("incoming traces continued %d/4; independent roots with propagation disabled %d/4", len(continued), len(roots)))
	case "resource":
		ok := len(changed.Resources) > 0
		expected, present := preservedProbeRequests(baseline, changed)
		preserved := (len(baseline.Spans) == 0 || len(changed.Spans) > 0) &&
			(len(baseline.Logs) == 0 || len(changed.Logs) > 0) &&
			(len(baseline.Metrics) == 0 || len(changed.Metrics) > 0) &&
			(expected == 0 || present == expected)
		for _, r := range changed.Resources {
			ok = ok && attributeValue(r, "probe.external") == "visible" && attributeValue(r, "service.name") == "external-probe"
		}
		check(len(baseline.Resources) > 0, ok && preserved, fmt.Sprintf("%d resources must retain probe.external=visible and OTEL_SERVICE_NAME precedence; workload requests preserved %d/%d", len(changed.Resources), present, expected))
	case "disabled":
		check(len(baseline.Spans) > 0, len(changed.Records) == 0, fmt.Sprintf("export requests %d -> %d", len(baseline.Records), len(changed.Records)))
	case "sampler", "sampler-arg":
		otherSignalsAlive := (len(baseline.Metrics) == 0 || len(changed.Metrics) > 0) && (len(baseline.Logs) == 0 || len(changed.Logs) > 0)
		check(len(baseline.Spans) > 0, len(changed.Spans) == 0 && otherSignalsAlive, fmt.Sprintf("spans %d -> %d; other baseline signals still exported: %t", len(baseline.Spans), len(changed.Spans), otherSignalsAlive))
	case "span-length", "attribute-length", "log-length":
		before, after := baseline.Spans, changed.Spans
		preserved, expected, present := true, 0, 0
		if e.Name == "log-length" {
			before, after = baseline.Logs, changed.Logs
			expected, present = limitedLogRecords(before, after, 8)
			preserved = expected == 0 || present == expected
		} else {
			expectedTraces := incomingProbeTraces(probeSpans(baseline))
			presentTraces := incomingServerTraces(after)
			expected, present = len(expectedTraces), len(presentTraces)
			preserved = expected == 0 || present == expected
		}
		check(maxLength(before) > 8, len(after) > 0 && maxLength(after) == 8 && preserved, fmt.Sprintf("maximum string attribute length %d -> %d; cap 8; baseline record identities preserved %d/%d", maxLength(before), maxLength(after), present, expected))
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
		sort.Strings(o.Violations)
	case "attribute-count", "event-attributes", "log-count":
		before, after, cap := baseline.Spans, changed.Spans, 2
		preserved, expected, present := true, 0, 0
		if e.Name == "event-attributes" {
			before, after, cap = events(baseline), events(changed), 1
			expected, present = limitedEventRecords(baseline, changed, cap)
			preserved = expected == 0 || present == expected
		}
		if e.Name == "log-count" {
			before, after, cap = baseline.Logs, changed.Logs, 1
			expected, present = limitedCountLogRecords(before, after, cap)
			preserved = expected == 0 || present == expected
		} else if e.Name != "event-attributes" {
			expected, present = preservedProbeRequests(baseline, changed)
			preserved = expected == 0 || present == expected
		}
		check(maxAttributes(before) > cap, len(after) > 0 && maxAttributes(after) == cap && dropped(after, "dropped_attributes_count") > 0 && preserved, fmt.Sprintf("maximum attributes %d -> %d; cap %d; dropped %d; baseline record identities preserved %d/%d", maxAttributes(before), maxAttributes(after), cap, dropped(after, "dropped_attributes_count"), present, expected))
	case "events":
		expected, present := suppressedEventRecords(baseline, changed)
		preserved := expected == 0 || present == expected
		check(len(events(baseline)) > 0, len(changed.Spans) > 0 && len(events(changed)) == 0 && dropped(changed.Spans, "dropped_events_count") > 0 && preserved, fmt.Sprintf("events %d -> %d; dropped %d; workload requests preserved %d/%d", len(events(baseline)), len(events(changed)), dropped(changed.Spans, "dropped_events_count"), present, expected))
	case "exemplars":
		before, preserved, remaining := suppressedExemplars(baseline, changed)
		check(before > 0, preserved == before && remaining == 0, fmt.Sprintf("exemplar-bearing metric identities preserved %d/%d; remaining exemplars %d", preserved, before, remaining))
	case "histogram":
		before, converted := convertedHistograms(baseline, changed)
		remaining := len(metricObjects(changed, "histogram"))
		check(before > 0, converted == before && remaining == 0, fmt.Sprintf("baseline histogram identities converted %d/%d; remaining explicit exports %d", converted, before, remaining))
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

func limitedLogRecords(before, after []object, limit int) (int, int) {
	eligible := map[string]int{}
	for _, record := range before {
		if body, ok := stringValue(field(record, "body")); ok && body != "" && maxLength([]object{record}) > limit {
			eligible[body]++
		}
	}
	preserved := map[string]int{}
	for _, record := range after {
		if body, ok := stringValue(field(record, "body")); ok && preserved[body] < eligible[body] {
			preserved[body]++
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

func limitedCountLogRecords(before, after []object, limit int) (int, int) {
	eligible := map[string]int{}
	for _, record := range before {
		if body, ok := stringValue(field(record, "body")); ok && body != "" && len(attributes(record)) > limit {
			eligible[body]++
		}
	}
	preserved := map[string]int{}
	for _, record := range after {
		if body, ok := stringValue(field(record, "body")); ok && preserved[body] < eligible[body] && len(attributes(record)) == limit && number(field(record, "dropped_attributes_count")) > 0 {
			preserved[body]++
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
	for _, span := range before.Spans {
		spanName, _ := field(span, "name").(string)
		for _, event := range objects(span, "events") {
			eventName, _ := field(event, "name").(string)
			if spanName != "" && eventName != "" && len(attributes(event)) > limit {
				eligible[spanName+"\x00"+eventName]++
			}
		}
	}
	preserved := map[string]int{}
	for _, span := range after.Spans {
		spanName, _ := field(span, "name").(string)
		for _, event := range objects(span, "events") {
			eventName, _ := field(event, "name").(string)
			key := spanName + "\x00" + eventName
			if preserved[key] < eligible[key] && len(attributes(event)) == limit && number(field(event, "dropped_attributes_count")) > 0 {
				preserved[key]++
			}
		}
	}
	return countIdentities(eligible), countIdentities(preserved)
}

func suppressedEventRecords(before, after capture) (int, int) {
	eligible := map[string]int{}
	for _, span := range before.Spans {
		if name, ok := field(span, "name").(string); ok && name != "" && len(objects(span, "events")) > 0 {
			eligible[name]++
		}
	}
	preserved := map[string]int{}
	for _, span := range after.Spans {
		name, _ := field(span, "name").(string)
		if preserved[name] < eligible[name] && len(objects(span, "events")) == 0 && number(field(span, "dropped_events_count")) > 0 {
			preserved[name]++
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

func metricID(stream metricStream) string {
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
		attributeSetID(stream.Resource, map[string]bool{
			"process.command_args": true,
			"process.pid":          true,
			"service.instance.id":  true,
		}),
	}
	encoded, _ := json.Marshal(parts)
	return string(encoded)
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

func suppressedExemplars(before, after capture) (int, int, int) {
	eligible := map[string]bool{}
	for _, stream := range captureMetricStreams(before) {
		if id, kind := metricID(stream), metricDataType(stream.Metric); id != "" && kind != "" && len(objects(stream.Metric, "data_points")) > 0 && len(objects(stream.Metric, "exemplars")) > 0 {
			eligible[id+"\x00"+kind] = true
		}
	}
	preserved := map[string]bool{}
	remaining := 0
	for _, stream := range captureMetricStreams(after) {
		id := metricID(stream) + "\x00" + metricDataType(stream.Metric)
		remaining += len(objects(stream.Metric, "exemplars"))
		if !eligible[id] {
			continue
		}
		if len(objects(stream.Metric, "data_points")) > 0 {
			preserved[id] = true
		}
	}
	return len(eligible), len(preserved), remaining
}

func convertedHistograms(before, after capture) (int, int) {
	eligible := map[string]bool{}
	for _, stream := range captureMetricStreams(before) {
		if id := metricID(stream); id != "" && len(objects(stream.Metric, "histogram")) > 0 && len(objects(stream.Metric, "data_points")) > 0 {
			eligible[id] = true
		}
	}
	converted := map[string]bool{}
	for _, stream := range captureMetricStreams(after) {
		id := metricID(stream)
		if eligible[id] && len(objects(stream.Metric, "exponential_histogram")) > 0 && len(objects(stream.Metric, "data_points")) > 0 {
			converted[id] = true
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
		baseID, kind := metricID(stream), metricDataType(stream.Metric)
		id := baseID + "\x00" + kind
		if baseID != "" && kind != "" && len(objects(stream.Metric, "data_points")) > 0 {
			eligible[id] = true
			if len(objects(stream.Metric, "exemplars")) > 0 {
				excluded[id] = true
			}
		}
	}
	for id := range excluded {
		delete(eligible, id)
	}
	preserved := map[string]bool{}
	count := 0
	for _, stream := range captureMetricStreams(after) {
		id := metricID(stream) + "\x00" + metricDataType(stream.Metric)
		if eligible[id] && len(objects(stream.Metric, "data_points")) > 0 {
			preserved[id] = true
			count += len(objects(stream.Metric, "exemplars"))
		}
	}
	return len(eligible), len(preserved), count
}
