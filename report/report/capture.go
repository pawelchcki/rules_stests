package report

import (
	"bytes"
	"encoding/base64"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"io"
	"sort"
	"strconv"
	"strings"
)

type CaptureDataset struct {
	Key         string           `json:"key"`
	Profile     string           `json:"profile"`
	Scenario    string           `json:"scenario"`
	Revision    string           `json:"revision"`
	Outcome     string           `json:"outcome"`
	Diagnostics []string         `json:"diagnostics,omitempty"`
	Resources   []map[string]any `json:"resources"`
	Scopes      []map[string]any `json:"scopes"`
	Spans       []CapturedSpan   `json:"spans"`
	Shape       ScenarioShape    `json:"shape"`
}
type CapturedSpan struct {
	Resource    int            `json:"resource"`
	Scope       int            `json:"scope"`
	Fields      map[string]any `json:"fields"`
	Parent      string         `json:"parent"`
	LinkTargets []string       `json:"linkTargets"`
}
type CaptureComparison struct {
	Left     string              `json:"left"`
	Right    string              `json:"right"`
	Scenario string              `json:"scenario"`
	Traces   []CaptureTraceMatch `json:"traces"`
}
type CaptureTraceMatch struct {
	Left  *TraceRef          `json:"left,omitempty"`
	Right *TraceRef          `json:"right,omitempty"`
	Spans []CaptureSpanMatch `json:"spans"`
}
type CaptureSpanMatch struct {
	Depth int   `json:"depth"`
	Left  []int `json:"left,omitempty"`
	Right []int `json:"right,omitempty"`
}

func object(v any) map[string]any { m, _ := v.(map[string]any); return m }
func array(v any) []any           { a, _ := v.([]any); return a }
func str(v any) string {
	if v == nil {
		return ""
	}
	return fmt.Sprint(v)
}
func canonical(v any) string { b, _ := json.Marshal(v); return string(b) }
func defaults(m map[string]any, values map[string]any) map[string]any {
	if m == nil {
		m = map[string]any{}
	}
	for k, v := range values {
		if m[k] == nil {
			m[k] = v
		}
	}
	return m
}

// Only protocol field spellings are normalized. Attribute names live in `key`
// values and are never rewritten. Decimal strings preserve 64-bit precision in JS.
func normalizeWire(v any) any {
	switch v := v.(type) {
	case json.Number:
		return v.String()
	case []any:
		out := make([]any, len(v))
		for i, c := range v {
			out[i] = normalizeWire(c)
		}
		return out
	case map[string]any:
		out := map[string]any{}
		for k, c := range v {
			parts := strings.Split(k, "_")
			key := parts[0]
			for _, p := range parts[1:] {
				if p != "" {
					key += strings.ToUpper(p[:1]) + p[1:]
				}
			}
			out[key] = normalizeWire(c)
		}
		// prost's AnyValue wraps the oneof in an additional `value` object.
		if len(out) == 1 {
			if value, exists := out["value"]; exists && value == nil {
				return map[string]any{}
			}
			if inner := object(out["value"]); inner != nil {
				for k := range inner {
					if strings.HasSuffix(k, "Value") {
						return inner
					}
				}
			}
		}
		for _, k := range []string{"attributes"} {
			if a := array(out[k]); a != nil {
				sort.SliceStable(a, func(i, j int) bool { return canonical(a[i]) < canonical(a[j]) })
			}
		}
		for _, kind := range []string{"arrayValue", "kvlistValue"} {
			if value := object(out[kind]); value != nil {
				defaults(value, map[string]any{"values": []any{}})
			}
		}
		if kv := object(out["kvlistValue"]); kv != nil {
			a := array(kv["values"])
			sort.SliceStable(a, func(i, j int) bool { return canonical(a[i]) < canonical(a[j]) })
		}
		if value, ok := out["doubleValue"]; ok {
			if number, err := strconv.ParseFloat(str(value), 64); err == nil {
				out["doubleValue"] = strconv.FormatFloat(number, 'g', -1, 64)
			}
		}
		if b := array(out["bytesValue"]); b != nil {
			raw := make([]byte, len(b))
			for i, x := range b {
				n, _ := strconv.ParseUint(str(x), 10, 8)
				raw[i] = byte(n)
			}
			out["bytesValue"] = base64.StdEncoding.EncodeToString(raw)
		}
		return out
	default:
		return v
	}
}
func enumValue(v any, prefix string, names []string) string {
	s := str(v)
	if n, e := strconv.Atoi(s); e == nil && n >= 0 && n < len(names) {
		return names[n]
	}
	s = strings.ToLower(strings.TrimPrefix(s, prefix))
	if s == "" {
		return names[0]
	}
	return s
}
func identity(v any, width int, optional bool) (string, error) {
	s := strings.ToLower(str(v))
	if optional && (s == "" || strings.Trim(s, "0") == "") {
		return "", nil
	}
	b, e := hex.DecodeString(s)
	if e != nil || len(b) != width || strings.Trim(s, "0") == "" {
		return "", fmt.Errorf("invalid trace/span identity %q", s)
	}
	return s, nil
}
func intern(items *[]map[string]any, v map[string]any) int {
	key := canonical(v)
	for i, x := range *items {
		if canonical(x) == key {
			return i
		}
	}
	*items = append(*items, v)
	return len(*items) - 1
}
func metadataFields(v any, schema any, scope bool) map[string]any {
	m := defaults(object(v), map[string]any{"attributes": []any{}, "droppedAttributesCount": "0"})
	if scope {
		m = defaults(m, map[string]any{"name": "", "version": ""})
	} else {
		m = defaults(m, map[string]any{"entityRefs": []any{}})
		for _, value := range array(m["entityRefs"]) {
			defaults(object(value), map[string]any{"schemaUrl": "", "type": "", "idKeys": []any{}, "descriptionKeys": []any{}})
		}
	}
	return map[string]any{"metadata": m, "schemaUrl": str(schema)}
}

// DecodeCapture handles trace readability errors as diagnostics. The assembler
// has already checked these bytes against the accepted receipt digest.
func DecodeCapture(receipt ValidationReceipt, input []byte) (d CaptureDataset) {
	d = CaptureDataset{Key: receipt.Profile + "/" + receipt.Scenario, Profile: receipt.Profile, Scenario: receipt.Scenario, Revision: receipt.Revision, Outcome: receipt.Outcome}
	d.Shape = ScenarioShape{Profile: d.Profile, Scenario: d.Scenario, ExactCounts: true, Scopes: map[string]int{}, Statuses: map[string]int{}}
	fail := func(err error) CaptureDataset {
		d.Diagnostics = append(d.Diagnostics, err.Error())
		d.Shape.Traces = nil
		return d
	}
	decoder := json.NewDecoder(bytes.NewReader(input))
	decoder.UseNumber()
	var records []any
	if e := decoder.Decode(&records); e != nil {
		return fail(fmt.Errorf("unreadable trace capture: %w", e))
	}
	if e := decoder.Decode(new(any)); e != io.EOF {
		return fail(fmt.Errorf("trailing capture data"))
	}
	for _, record := range records {
		r := object(record)
		if str(r["signal"]) != "traces" {
			continue
		}
		payload := object(normalizeWire(r["payload"]))
		resources, ok := payload["resourceSpans"].([]any)
		if !ok {
			return fail(fmt.Errorf("unreadable resourceSpans"))
		}
		for _, resource := range resources {
			rs := object(resource)
			ri := intern(&d.Resources, metadataFields(rs["resource"], rs["schemaUrl"], false))
			groups, ok := rs["scopeSpans"].([]any)
			if !ok {
				return fail(fmt.Errorf("unreadable scopeSpans"))
			}
			for _, group := range groups {
				ss := object(group)
				si := intern(&d.Scopes, metadataFields(ss["scope"], ss["schemaUrl"], true))
				spans, ok := ss["spans"].([]any)
				if !ok {
					return fail(fmt.Errorf("unreadable spans"))
				}
				for _, span := range spans {
					fields := object(span)
					if fields == nil {
						return fail(fmt.Errorf("unreadable span"))
					}
					fields = defaults(fields, map[string]any{"traceState": "", "parentSpanId": "", "name": "", "startTimeUnixNano": "0", "endTimeUnixNano": "0", "attributes": []any{}, "events": []any{}, "links": []any{}, "flags": "0", "droppedAttributesCount": "0", "droppedEventsCount": "0", "droppedLinksCount": "0"})
					fields["kind"] = enumValue(fields["kind"], "SPAN_KIND_", []string{"unspecified", "internal", "server", "client", "producer", "consumer"})
					status := defaults(object(fields["status"]), map[string]any{"code": "0", "message": ""})
					status["code"] = enumValue(status["code"], "STATUS_CODE_", []string{"unset", "ok", "error"})
					fields["status"] = status
					for _, event := range array(fields["events"]) {
						defaults(object(event), map[string]any{"timeUnixNano": "0", "name": "", "attributes": []any{}, "droppedAttributesCount": "0"})
					}
					for _, link := range array(fields["links"]) {
						defaults(object(link), map[string]any{"traceState": "", "attributes": []any{}, "droppedAttributesCount": "0", "flags": "0"})
					}
					d.Spans = append(d.Spans, CapturedSpan{Resource: ri, Scope: si, Fields: fields})
				}
			}
		}
	}
	if len(d.Spans) == 0 {
		return fail(fmt.Errorf("no captured trace spans available"))
	}
	ids := map[string]int{}
	traces := map[string][]int{}
	parents := make([]int, len(d.Spans))
	children := make([][]int, len(d.Spans))
	traceIDs := make([]string, len(d.Spans))
	spanIDs := make([]string, len(d.Spans))
	parentIDs := make([]string, len(d.Spans))
	for i, s := range d.Spans {
		var e error
		traceIDs[i], e = identity(s.Fields["traceId"], 16, false)
		if e != nil {
			return fail(e)
		}
		spanIDs[i], e = identity(s.Fields["spanId"], 8, false)
		if e != nil {
			return fail(e)
		}
		parentIDs[i], e = identity(s.Fields["parentSpanId"], 8, true)
		if e != nil {
			return fail(e)
		}
		key := traceIDs[i] + "/" + spanIDs[i]
		if _, ok := ids[key]; ok {
			return fail(fmt.Errorf("duplicate span identity %s", key))
		}
		ids[key] = i
		traces[traceIDs[i]] = append(traces[traceIDs[i]], i)
	}
	for i := range d.Spans {
		parents[i] = -1
		if parentIDs[i] != "" {
			if p, ok := ids[traceIDs[i]+"/"+parentIDs[i]]; ok {
				parents[i] = p
				children[p] = append(children[p], i)
			}
		}
	}
	colors := make([]int, len(d.Spans))
	fingerprints := make([]string, len(d.Spans))
	var fingerprint func(int, int) (string, error)
	fingerprint = func(i, depth int) (string, error) {
		if colors[i] == 1 {
			return "", fmt.Errorf("cycle in captured trace")
		}
		if depth > 128 {
			return "", fmt.Errorf("captured trace exceeds 128 levels")
		}
		if colors[i] == 2 {
			return fingerprints[i], nil
		}
		colors[i] = 1
		cs := []string{}
		for _, c := range children[i] {
			f, e := fingerprint(c, depth+1)
			if e != nil {
				return "", e
			}
			cs = append(cs, f)
		}
		sort.Strings(cs)
		fingerprints[i] = digest([]byte(canonical([]any{str(d.Spans[i].Fields["kind"]), NormalizeSpanName(str(d.Spans[i].Fields["name"])), cs})))
		colors[i] = 2
		return fingerprints[i], nil
	}
	for i := range d.Spans {
		if _, e := fingerprint(i, 0); e != nil {
			return fail(e)
		}
	}
	// Structural paths retain parent and local link relationships without IDs.
	var path func(int) string
	path = func(i int) string {
		label := str(d.Spans[i].Fields["kind"]) + " " + NormalizeSpanName(str(d.Spans[i].Fields["name"])) + " [" + fingerprints[i][:12] + "]"
		if parents[i] < 0 {
			return label
		}
		return path(parents[i]) + " / " + label
	}
	externalParents := map[string][]string{}
	for i := range d.Spans {
		if parents[i] < 0 && parentIDs[i] != "" {
			key := traceIDs[i] + "/" + parentIDs[i]
			externalParents[key] = append(externalParents[key], fingerprints[i])
		}
	}
	for _, children := range externalParents {
		sort.Strings(children)
	}
	for i := range d.Spans {
		if parents[i] >= 0 {
			d.Spans[i].Parent = path(parents[i])
		} else if parentIDs[i] != "" {
			d.Spans[i].Parent = "external parent (partial trace), children structure " + digest([]byte(canonical(externalParents[traceIDs[i]+"/"+parentIDs[i]])))
		} else {
			d.Spans[i].Parent = "root"
		}
		externalLinks := map[string]int{}
		for linkIndex, l := range array(d.Spans[i].Fields["links"]) {
			link := object(l)
			tid, e := identity(link["traceId"], 16, false)
			if e != nil {
				return fail(e)
			}
			sid, e := identity(link["spanId"], 8, false)
			if e != nil {
				return fail(e)
			}
			target := "external trace/span"
			if tid == traceIDs[i] {
				target = "external span in same trace"
			}
			if sid == parentIDs[i] && tid == traceIDs[i] {
				target = "external parent"
			}
			if j, ok := ids[tid+"/"+sid]; ok {
				relation := "in another trace "
				if tid == traceIDs[i] {
					relation = "in same trace "
				}
				target = "captured " + relation + path(j)
				if j == i {
					target = "self"
				}
			} else {
				key := tid + "/" + sid
				if previous, exists := externalLinks[key]; exists {
					target += fmt.Sprintf(" (same target as link %d)", previous)
				} else {
					externalLinks[key] = linkIndex
				}
			}
			d.Spans[i].LinkTargets = append(d.Spans[i].LinkTargets, target)
		}
	}
	var groups func([]int) []SpanGroup
	groups = func(indices []int) []SpanGroup {
		byKey := map[string][]int{}
		for _, i := range indices {
			byKey[fingerprints[i]] = append(byKey[fingerprints[i]], i)
		}
		keys := make([]string, 0, len(byKey))
		for k := range byKey {
			keys = append(keys, k)
		}
		sort.Strings(keys)
		out := []SpanGroup{}
		for _, k := range keys {
			occ := byKey[k]
			sort.Ints(occ)
			s := d.Spans[occ[0]]
			for _, i := range occ {
				if str(d.Spans[i].Fields["name"]) < str(s.Fields["name"]) {
					s = d.Spans[i]
				}
			}
			cs := []int{}
			for _, i := range occ {
				cs = append(cs, children[i]...)
			}
			out = append(out, SpanGroup{Count: len(occ), ExactCount: true, Span: SpanNode{Name: str(s.Fields["name"]), Kind: str(s.Fields["kind"]), Occurrences: occ, Children: groups(cs)}})
		}
		return out
	}
	type traceStructure struct {
		roots    []int
		count    int
		coverage string
	}
	structures := map[string]*traceStructure{}
	for _, indices := range traces {
		roots := []int{}
		keys := []string{}
		coverage := "complete"
		for _, i := range indices {
			if parents[i] < 0 {
				roots = append(roots, i)
				keys = append(keys, fingerprints[i])
				if parentIDs[i] != "" {
					coverage = "partial"
				}
			}
		}
		sort.Strings(keys)
		key := coverage + canonical(keys)
		if structures[key] == nil {
			structures[key] = &traceStructure{coverage: coverage}
		}
		g := structures[key]
		g.roots = append(g.roots, roots...)
		g.count++
	}
	keys := []string{}
	for k := range structures {
		keys = append(keys, k)
	}
	sort.Strings(keys)
	for _, k := range keys {
		g := structures[k]
		d.Shape.Traces = append(d.Shape.Traces, TraceGroup{Count: g.count, ExactCount: true, Coverage: g.coverage, Roots: groups(g.roots)})
	}
	d.Shape.TraceCount = len(traces)
	d.Shape.SpanCount = len(d.Spans)
	return d
}
