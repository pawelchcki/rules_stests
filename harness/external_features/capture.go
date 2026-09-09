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
type capture struct {
	Records                         []object
	Spans, Logs, Metrics, Resources []object
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
		switch field(r, "signal") {
		case "traces":
			c.Spans = append(c.Spans, objects(p, "spans")...)
		case "logs":
			c.Logs = append(c.Logs, objects(p, "log_records")...)
		case "metrics":
			c.Metrics = append(c.Metrics, objects(p, "metrics")...)
		default:
			return capture{}, fmt.Errorf("unknown signal %v", field(r, "signal"))
		}
		c.Resources = append(c.Resources, objects(p, "resource")...)
	}
	return c, nil
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
			if s, ok := stringValue(field(a, "value")); ok {
				if size := utf8.RuneCountInString(s); size > n {
					n = size
				}
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
func exemplarCount(c capture) int {
	n := 0
	for _, m := range c.Metrics {
		n += len(objects(m, "exemplars"))
	}
	return n
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
		violations := map[string]bool{}
		for _, r := range changed.Resources {
			name := attributeValue(r, "service.name")
			ok = ok && (name == "unknown_service" || (strings.HasPrefix(name, "unknown_service:") && len(name) > len("unknown_service:")))
			if name == "" {
				kind := "missing"
				for _, a := range attributes(r) {
					if field(a, "key") == "service.name" {
						kind = "empty"
					}
				}
				violations["service.name="+kind] = true
			}
		}
		for v := range violations {
			o.Violations = append(o.Violations, v)
		}
		sort.Strings(o.Violations)
		check(len(baseline.Resources) > 0, ok, "empty OTEL_SERVICE_NAME must produce unknown_service or unknown_service:<executable>")
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
			preserved = len(probeSpans(changed)) == 4
		}
		check(prior > 1, actual == 1 && preserved, fmt.Sprintf("maximum %s batch %d -> %d; records %d -> %d", signal, prior, actual, len(before), len(after)))
	case "exemplars-always-on":
		eligible, after := unsampledExemplars(baseline, changed)
		check(eligible > 0 && len(baseline.Spans) == 0, len(changed.Spans) == 0 && after > 0, fmt.Sprintf("%d control metric names without exemplars; AlwaysOn exemplars for those names %d; exported spans %d", eligible, after, len(changed.Spans)))
	case "request-headers":
		before, after := probeSpans(baseline), probeSpans(changed)
		captured := 0
		for _, s := range after {
			if headerArray(s) {
				captured++
			}
		}
		check(len(before) == 4, len(after) == 4 && captured == 4, fmt.Sprintf("probe server spans %d -> %d; exact header arrays %d/4", len(before), len(after), captured))
	case "propagation-none":
		before, after := probeSpans(baseline), probeSpans(changed)
		continued := map[string]bool{}
		roots := 0
		for _, s := range before {
			if id, ok := field(s, "trace_id").(string); ok && incomingTrace(id) && field(s, "parent_span_id") == "00f067aa0ba902b7" {
				continued[id] = true
			}
		}
		for _, s := range after {
			if id, ok := field(s, "trace_id").(string); ok && validTrace(id) && !incomingTrace(id) && field(s, "parent_span_id") == "" {
				roots++
			}
		}
		check(len(before) == 4 && len(continued) == 4, len(after) == 4 && roots == 4, fmt.Sprintf("incoming traces continued %d/4; independent roots with propagation disabled %d/4", len(continued), roots))
	case "resource":
		ok := len(changed.Resources) > 0
		for _, r := range changed.Resources {
			ok = ok && attributeValue(r, "probe.external") == "visible" && attributeValue(r, "service.name") == "external-probe"
		}
		check(len(baseline.Resources) > 0, ok, fmt.Sprintf("%d resources must retain probe.external=visible and OTEL_SERVICE_NAME precedence", len(changed.Resources)))
	case "disabled":
		check(len(baseline.Spans) > 0, len(changed.Records) == 0, fmt.Sprintf("export requests %d -> %d", len(baseline.Records), len(changed.Records)))
	case "sampler", "sampler-arg":
		otherSignalsAlive := (len(baseline.Metrics) == 0 || len(changed.Metrics) > 0) && (len(baseline.Logs) == 0 || len(changed.Logs) > 0)
		check(len(baseline.Spans) > 0, len(changed.Spans) == 0 && otherSignalsAlive, fmt.Sprintf("spans %d -> %d; other baseline signals still exported: %t", len(baseline.Spans), len(changed.Spans), otherSignalsAlive))
	case "span-length", "attribute-length", "log-length":
		before, after := baseline.Spans, changed.Spans
		if e.Name == "log-length" {
			before, after = baseline.Logs, changed.Logs
		}
		check(maxLength(before) > 8, len(after) > 0 && maxLength(after) == 8, fmt.Sprintf("maximum string attribute length %d -> %d; cap 8", maxLength(before), maxLength(after)))
		violations := map[string]bool{}
		for _, item := range after {
			for _, a := range attributes(item) {
				if s, ok := stringValue(field(a, "value")); ok && utf8.RuneCountInString(s) > 8 {
					violations[fmt.Sprintf("%v=%d", field(a, "key"), utf8.RuneCountInString(s))] = true
				}
			}
		}
		for v := range violations {
			o.Violations = append(o.Violations, v)
		}
		sort.Strings(o.Violations)
	case "attribute-count", "event-attributes", "log-count":
		before, after, cap := baseline.Spans, changed.Spans, 2
		if e.Name == "event-attributes" {
			before, after, cap = events(baseline), events(changed), 1
		}
		if e.Name == "log-count" {
			before, after, cap = baseline.Logs, changed.Logs, 1
		}
		check(maxAttributes(before) > cap, len(after) > 0 && maxAttributes(after) == cap && dropped(after, "dropped_attributes_count") > 0, fmt.Sprintf("maximum attributes %d -> %d; cap %d; dropped %d", maxAttributes(before), maxAttributes(after), cap, dropped(after, "dropped_attributes_count")))
	case "events":
		check(len(events(baseline)) > 0, len(changed.Spans) > 0 && len(events(changed)) == 0 && dropped(changed.Spans, "dropped_events_count") > 0, fmt.Sprintf("events %d -> %d; dropped %d", len(events(baseline)), len(events(changed)), dropped(changed.Spans, "dropped_events_count")))
	case "exemplars":
		check(exemplarCount(baseline) > 0, len(changed.Metrics) > 0 && exemplarCount(changed) == 0, fmt.Sprintf("exemplars %d -> %d; metric descriptors %d", exemplarCount(baseline), exemplarCount(changed), len(changed.Metrics)))
	case "histogram":
		before, after := len(metricObjects(baseline, "histogram")), len(metricObjects(changed, "exponential_histogram"))
		check(before > 0, after > 0 && len(metricObjects(changed, "histogram")) == 0, fmt.Sprintf("explicit histogram exports %d -> %d; exponential exports %d", before, len(metricObjects(changed, "histogram")), after))
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
func validTrace(id string) bool {
	decoded, err := hex.DecodeString(id)
	return err == nil && len(decoded) == 16 && id != strings.Repeat("0", 32)
}
func headerArray(s object) bool {
	for _, a := range attributes(s) {
		if field(a, "key") == "http.request.header.x_probe_feature" {
			arrays := objects(field(a, "value"), "array_value")
			if len(arrays) != 1 {
				return false
			}
			values, ok := field(arrays[0], "values").([]any)
			if !ok || len(values) != 1 {
				return false
			}
			value, ok := stringValue(values[0])
			return ok && value == "visible"
		}
	}
	return false
}

// Active-request metrics may record against a sampled remote parent before
// the server creates its nonrecording span. Exclude such metric names from
// both sides instead of mistaking their TraceBased exemplars for AlwaysOn.
func unsampledExemplars(before, after capture) (int, int) {
	eligible := map[string]bool{}
	excluded := map[string]bool{}
	for _, m := range before.Metrics {
		if name, ok := field(m, "name").(string); ok && name != "" && len(objects(m, "data_points")) > 0 {
			eligible[name] = true
			if len(objects(m, "exemplars")) > 0 {
				excluded[name] = true
			}
		}
	}
	for name := range excluded {
		delete(eligible, name)
	}
	count := 0
	for _, m := range after.Metrics {
		if name, ok := field(m, "name").(string); ok && eligible[name] {
			count += len(objects(m, "exemplars"))
		}
	}
	return len(eligible), count
}
