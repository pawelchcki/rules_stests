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
	Resource                int            `json:"resource"`
	Scope                   int            `json:"scope"`
	Fields                  map[string]any `json:"fields"`
	Parent                  string         `json:"parent"`
	ParentWithoutScope      string         `json:"parentWithoutScope"`
	LinkTargets             []string       `json:"linkTargets"`
	LinkTargetsWithoutScope []string       `json:"linkTargetsWithoutScope"`
	TraceRoots              string         `json:"traceRoots,omitempty"`
	TraceRootsWithoutScope  string         `json:"traceRootsWithoutScope,omitempty"`
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
func repeatedField(v any, name string) ([]any, error) {
	if v == nil {
		return nil, nil
	}
	items, ok := v.([]any)
	if !ok {
		return nil, fmt.Errorf("unreadable %s", name)
	}
	return items, nil
}
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
func normalizeWire(v any) (any, error) {
	return normalizeWireContext(v, "")
}

func canonicalBytes(value string) (string, bool) {
	normalized := strings.NewReplacer("-", "+", "_", "/").Replace(value)
	for _, encoding := range []*base64.Encoding{base64.StdEncoding, base64.RawStdEncoding} {
		if raw, err := encoding.DecodeString(normalized); err == nil {
			return base64.StdEncoding.EncodeToString(raw), true
		}
	}
	return "", false
}

func normalizeWireContext(v any, context string) (any, error) {
	switch v := v.(type) {
	case json.Number:
		return v.String(), nil
	case []any:
		out := make([]any, len(v))
		childContext := ""
		if context == "anyValues" {
			childContext = "anyValue"
		} else if context == "keyValues" {
			childContext = "keyValue"
		}
		for i, c := range v {
			var err error
			out[i], err = normalizeWireContext(c, childContext)
			if err != nil {
				return nil, err
			}
		}
		return out, nil
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
			if _, exists := out[key]; exists {
				return nil, fmt.Errorf("duplicate OTLP JSON field spellings for %q", key)
			}
			childContext := ""
			switch {
			case context == "keyValue" && key == "value":
				childContext = "anyValue"
			case context == "anyValue" && key == "value":
				childContext = "anyValue"
			case context == "anyValue" && key == "arrayValue":
				childContext = "arrayValue"
			case context == "anyValue" && key == "kvlistValue":
				childContext = "keyValueList"
			case context == "arrayValue" && key == "values":
				childContext = "anyValues"
			case context == "keyValueList" && key == "values":
				childContext = "keyValues"
			case key == "attributes" || key == "filteredAttributes":
				childContext = "keyValues"
			case key == "body":
				childContext = "anyValue"
			}
			value, err := normalizeWireContext(c, childContext)
			if err != nil {
				return nil, err
			}
			out[key] = value
		}
		// prost's AnyValue wraps the oneof in an additional `value` object.
		// Restrict this unwrapping to known AnyValue positions: an omitted
		// KeyValue.key otherwise has the same single-field wire shape.
		if context == "anyValue" && len(out) == 1 {
			if value, exists := out["value"]; exists && value == nil {
				return map[string]any{}, nil
			}
			for key, value := range out {
				switch key {
				case "stringValue", "boolValue", "intValue", "doubleValue", "arrayValue", "kvlistValue", "bytesValue":
					if value == nil {
						return map[string]any{}, nil
					}
				}
			}
			if inner := object(out["value"]); inner != nil {
				for k := range inner {
					if strings.HasSuffix(k, "Value") {
						return inner, nil
					}
				}
			}
		}
		if context == "keyValue" {
			defaults(out, map[string]any{"key": ""})
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
		} else if value, ok := out["bytesValue"].(string); ok {
			if canonical, valid := canonicalBytes(value); valid {
				out["bytesValue"] = canonical
			}
		}
		return out, nil
	default:
		return v, nil
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
	if optional && s == "" {
		return "", nil
	}
	b, e := hex.DecodeString(s)
	if e != nil || len(b) != width || strings.Trim(s, "0") == "" {
		return "", fmt.Errorf("invalid trace/span identity %q", s)
	}
	return s, nil
}
func intern(items *[]map[string]any, indexes map[string]int, v map[string]any) int {
	key := canonical(v)
	if i, ok := indexes[key]; ok {
		return i
	}
	*items = append(*items, v)
	i := len(*items) - 1
	indexes[key] = i
	return i
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

func semanticSpanProjection(d *CaptureDataset, index int, includeScope bool) map[string]any {
	span := d.Spans[index]
	fields := map[string]any{}
	for key, value := range span.Fields {
		switch key {
		case "traceId", "spanId", "parentSpanId", "startTimeUnixNano", "endTimeUnixNano", "events", "links":
			continue
		default:
			fields[key] = value
		}
	}
	events := []any{}
	for _, value := range array(span.Fields["events"]) {
		event := map[string]any{}
		for key, field := range object(value) {
			if key != "timeUnixNano" {
				event[key] = field
			}
		}
		events = append(events, event)
	}
	fields["events"] = events
	links := []any{}
	for i, value := range array(span.Fields["links"]) {
		link := map[string]any{}
		for key, field := range object(value) {
			if key != "traceId" && key != "spanId" {
				link[key] = field
			}
		}
		targets := span.LinkTargets
		if !includeScope && len(span.LinkTargetsWithoutScope) == len(span.LinkTargets) {
			targets = span.LinkTargetsWithoutScope
		}
		if i < len(targets) {
			link["relationship"] = targets[i]
		}
		links = append(links, link)
	}
	fields["links"] = links
	projection := map[string]any{"span": fields, "resource": d.Resources[span.Resource]}
	if includeScope {
		projection["scope"] = d.Scopes[span.Scope]
	}
	return projection
}

// DecodeCapture handles trace readability errors as diagnostics. The assembler
// has already checked these bytes against the accepted receipt digest.
func DecodeCapture(receipt ValidationReceipt, input []byte) (d CaptureDataset) {
	d = CaptureDataset{Key: receipt.Profile + "/" + receipt.Scenario, Profile: receipt.Profile, Scenario: receipt.Scenario, Revision: receipt.Revision, Outcome: receipt.Outcome}
	d.Shape = ScenarioShape{Profile: d.Profile, Scenario: d.Scenario, ExactCounts: true, Scopes: map[string]int{}, Statuses: map[string]int{}}
	resourceIndexes := map[string]int{}
	scopeIndexes := map[string]int{}
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
		normalized, err := normalizeWire(r["payload"])
		if err != nil {
			return fail(err)
		}
		payload := object(normalized)
		if payload == nil {
			return fail(fmt.Errorf("unreadable trace payload"))
		}
		resources, err := repeatedField(payload["resourceSpans"], "resourceSpans")
		if err != nil {
			return fail(err)
		}
		for _, resource := range resources {
			rs := object(resource)
			if rs == nil {
				return fail(fmt.Errorf("unreadable resourceSpan"))
			}
			groups, err := repeatedField(rs["scopeSpans"], "scopeSpans")
			if err != nil {
				return fail(err)
			}
			for _, group := range groups {
				ss := object(group)
				if ss == nil {
					return fail(fmt.Errorf("unreadable scopeSpan"))
				}
				spans, err := repeatedField(ss["spans"], "spans")
				if err != nil {
					return fail(err)
				}
				if len(spans) == 0 {
					continue
				}
				ri := intern(&d.Resources, resourceIndexes, metadataFields(rs["resource"], rs["schemaUrl"], false))
				si := intern(&d.Scopes, scopeIndexes, metadataFields(ss["scope"], ss["schemaUrl"], true))
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
		if depth >= 128 {
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
	buildTargetOccurrenceKeys := func(includeScope bool) []string {
		keys := make([]string, len(d.Spans))
		var key func(int) string
		key = func(i int) string {
			if keys[i] != "" {
				return keys[i]
			}
			parent := "root"
			if parents[i] >= 0 {
				parent = key(parents[i])
			} else if parentIDs[i] != "" {
				parent = "external parent"
			}
			keys[i] = digest([]byte(canonical([]any{parent, semanticSpanProjection(&d, i, includeScope)})))[:12]
			return keys[i]
		}
		for i := range d.Spans {
			key(i)
		}
		return keys
	}
	sourceOccurrenceKeys := buildTargetOccurrenceKeys(true)
	sourceOccurrenceKeysWithoutScope := buildTargetOccurrenceKeys(false)
	buildGraphAwareTargetKeys := func(base []string, targetDigests map[string]string) ([]string, error) {
		type graphEdge struct {
			relationship string
			target       int
			external     string
			shared       string
		}
		edges := make([][]graphEdge, len(d.Spans))
		externalIncoming := map[string][]string{}
		for i := range d.Spans {
			for linkIndex, value := range array(d.Spans[i].Fields["links"]) {
				link := object(value)
				tid, err := identity(link["traceId"], 16, false)
				if err != nil {
					return nil, err
				}
				sid, err := identity(link["spanId"], 8, false)
				if err != nil {
					return nil, err
				}
				targetKey := tid + "/" + sid
				edge := graphEdge{relationship: "external trace/span", target: -1, external: targetKey, shared: targetDigests[targetKey]}
				if tid == traceIDs[i] {
					edge.relationship = "external span in same trace"
				}
				if sid == parentIDs[i] && tid == traceIDs[i] {
					edge.relationship = "external parent"
				}
				if j, ok := ids[targetKey]; ok {
					edge.target = j
					edge.external = ""
					if j == i {
						edge.relationship = "self"
					} else if tid == traceIDs[i] {
						edge.relationship = "captured in same trace"
					} else {
						edge.relationship = "captured in another trace"
					}
				} else {
					externalIncoming[targetKey] = append(externalIncoming[targetKey], canonical([]any{base[i], linkIndex, edge.relationship}))
				}
				edges[i] = append(edges[i], edge)
			}
		}
		externalLabels := map[string]string{}
		for target, incoming := range externalIncoming {
			sort.Strings(incoming)
			externalLabels[target] = digest([]byte(canonical(incoming)))[:12]
		}

		// Collapse cycles once, then label the resulting component DAG from its
		// leaves. This retains complete reachable-graph identity without
		// serializing the same suffix independently for every span.
		indexes := make([]int, len(d.Spans))
		lowlinks := make([]int, len(d.Spans))
		onStack := make([]bool, len(d.Spans))
		for i := range indexes {
			indexes[i] = -1
		}
		stack := []int{}
		components := [][]int{}
		nextIndex := 0
		var connect func(int)
		connect = func(i int) {
			indexes[i], lowlinks[i] = nextIndex, nextIndex
			nextIndex++
			stack = append(stack, i)
			onStack[i] = true
			for _, edge := range edges[i] {
				if edge.target < 0 {
					continue
				}
				if indexes[edge.target] < 0 {
					connect(edge.target)
					if lowlinks[edge.target] < lowlinks[i] {
						lowlinks[i] = lowlinks[edge.target]
					}
				} else if onStack[edge.target] && indexes[edge.target] < lowlinks[i] {
					lowlinks[i] = indexes[edge.target]
				}
			}
			if lowlinks[i] != indexes[i] {
				return
			}
			component := []int{}
			for {
				last := len(stack) - 1
				member := stack[last]
				stack = stack[:last]
				onStack[member] = false
				component = append(component, member)
				if member == i {
					break
				}
			}
			components = append(components, component)
		}
		for i := range d.Spans {
			if indexes[i] < 0 {
				connect(i)
			}
		}
		componentOf := make([]int, len(d.Spans))
		for component, members := range components {
			for _, member := range members {
				componentOf[member] = component
			}
		}

		keys := make([]string, len(d.Spans))
		componentKeys := make([]string, len(components))
		componentState := make([]int, len(components))
		var labelComponent func(int)
		labelComponent = func(component int) {
			if componentState[component] == 2 {
				return
			}
			componentState[component] = 1
			for _, member := range components[component] {
				for _, edge := range edges[member] {
					if edge.target >= 0 && componentOf[edge.target] != component {
						labelComponent(componentOf[edge.target])
					}
				}
			}
			descriptions := make([]string, 0, len(components[component]))
			memberDescriptions := map[int]string{}
			for _, member := range components[component] {
				outgoing := make([]any, 0, len(edges[member]))
				for _, edge := range edges[member] {
					descriptor := map[string]any{"relationship": edge.relationship}
					if edge.target < 0 {
						descriptor["externalTarget"] = externalLabels[edge.external]
					} else if componentOf[edge.target] == component {
						descriptor["componentTarget"] = base[edge.target]
					} else {
						descriptor["target"] = keys[edge.target]
					}
					if edge.shared != "" {
						descriptor["sharedTarget"] = edge.shared
					}
					outgoing = append(outgoing, descriptor)
				}
				memberDescriptions[member] = canonical([]any{base[member], outgoing})
				descriptions = append(descriptions, memberDescriptions[member])
			}
			sort.Strings(descriptions)
			componentKeys[component] = digest([]byte(canonical(descriptions)))[:12]
			for _, member := range components[component] {
				keys[member] = digest([]byte(canonical([]any{memberDescriptions[member], componentKeys[component]})))[:12]
			}
			componentState[component] = 2
		}
		for component := range components {
			labelComponent(component)
		}
		return keys, nil
	}
	sourceOccurrenceKeys, err := buildGraphAwareTargetKeys(sourceOccurrenceKeys, nil)
	if err != nil {
		return fail(err)
	}
	sourceOccurrenceKeysWithoutScope, err = buildGraphAwareTargetKeys(sourceOccurrenceKeysWithoutScope, nil)
	if err != nil {
		return fail(err)
	}
	linkTargetSources := map[string][]string{}
	linkTargetSourcesWithoutScope := map[string][]string{}
	for i := range d.Spans {
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
			key := tid + "/" + sid
			linkTargetSources[key] = append(linkTargetSources[key], fmt.Sprintf("%s occurrence %s link %d", path(i), sourceOccurrenceKeys[i], linkIndex))
			linkTargetSourcesWithoutScope[key] = append(linkTargetSourcesWithoutScope[key], fmt.Sprintf("%s occurrence %s link %d", path(i), sourceOccurrenceKeysWithoutScope[i], linkIndex))
		}
	}
	for _, sources := range linkTargetSources {
		sort.Strings(sources)
	}
	for _, sources := range linkTargetSourcesWithoutScope {
		sort.Strings(sources)
	}
	sharedTargetDigests := func(targetSources map[string][]string) map[string]string {
		result := map[string]string{}
		for key, sources := range targetSources {
			if len(sources) > 1 {
				result[key] = digest([]byte(canonical(sources)))[:12]
			}
		}
		return result
	}
	linkTargetDigests := sharedTargetDigests(linkTargetSources)
	linkTargetDigestsWithoutScope := sharedTargetDigests(linkTargetSourcesWithoutScope)
	targetOccurrenceKeys, err := buildGraphAwareTargetKeys(sourceOccurrenceKeys, linkTargetDigests)
	if err != nil {
		return fail(err)
	}
	targetOccurrenceKeysWithoutScope, err := buildGraphAwareTargetKeys(sourceOccurrenceKeysWithoutScope, linkTargetDigestsWithoutScope)
	if err != nil {
		return fail(err)
	}
	for i := range d.Spans {
		for _, l := range array(d.Spans[i].Fields["links"]) {
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
			targetWithoutScope := target
			if tid == traceIDs[i] {
				target = "external span in same trace"
				targetWithoutScope = target
			}
			if sid == parentIDs[i] && tid == traceIDs[i] {
				target = "external parent"
				targetWithoutScope = target
			}
			if j, ok := ids[tid+"/"+sid]; ok {
				relation := "in another trace "
				if tid == traceIDs[i] {
					relation = "in same trace "
				}
				target = "captured " + relation + path(j) + " occurrence " + targetOccurrenceKeys[j]
				targetWithoutScope = "captured " + relation + path(j) + " occurrence " + targetOccurrenceKeysWithoutScope[j]
				if j == i {
					target = "self"
					targetWithoutScope = target
				}
			}
			if shared := linkTargetDigests[tid+"/"+sid]; shared != "" {
				target += " (shared target " + shared + ")"
			}
			if shared := linkTargetDigestsWithoutScope[tid+"/"+sid]; shared != "" {
				targetWithoutScope += " (shared target " + shared + ")"
			}
			d.Spans[i].LinkTargets = append(d.Spans[i].LinkTargets, target)
			d.Spans[i].LinkTargetsWithoutScope = append(d.Spans[i].LinkTargetsWithoutScope, targetWithoutScope)
		}
	}
	buildOccurrenceKeys := func(includeScope bool) []string {
		keys := make([]string, len(d.Spans))
		var key func(int) string
		key = func(i int) string {
			if keys[i] != "" {
				return keys[i]
			}
			parent := "root"
			if parents[i] >= 0 {
				parent = key(parents[i])
			} else if parentIDs[i] != "" {
				parent = "external parent"
			}
			keys[i] = digest([]byte(canonical([]any{parent, semanticSpanProjection(&d, i, includeScope)})))[:12]
			return keys[i]
		}
		for i := range d.Spans {
			key(i)
		}
		return keys
	}
	occurrenceKeys := buildOccurrenceKeys(true)
	occurrenceKeysWithoutScope := buildOccurrenceKeys(false)
	buildExternalParents := func(keys []string) map[string][]string {
		result := map[string][]string{}
		for i := range d.Spans {
			if parents[i] < 0 && parentIDs[i] != "" {
				key := traceIDs[i] + "/" + parentIDs[i]
				result[key] = append(result[key], keys[i])
			}
		}
		for _, children := range result {
			sort.Strings(children)
		}
		return result
	}
	externalParents := buildExternalParents(occurrenceKeys)
	externalParentsWithoutScope := buildExternalParents(occurrenceKeysWithoutScope)
	for i := range d.Spans {
		if parents[i] >= 0 {
			d.Spans[i].Parent = path(parents[i]) + " occurrence " + occurrenceKeys[parents[i]]
			d.Spans[i].ParentWithoutScope = path(parents[i]) + " occurrence " + occurrenceKeysWithoutScope[parents[i]]
		} else if parentIDs[i] != "" {
			key := traceIDs[i] + "/" + parentIDs[i]
			d.Spans[i].Parent = "external parent (partial trace), children occurrences " + digest([]byte(canonical(externalParents[key])))
			d.Spans[i].ParentWithoutScope = "external parent (partial trace), children occurrences " + digest([]byte(canonical(externalParentsWithoutScope[key])))
		} else {
			d.Spans[i].Parent = "root"
			d.Spans[i].ParentWithoutScope = "root"
		}
	}
	for _, indices := range traces {
		roots := []int{}
		withScope := []string{}
		withoutScope := []string{}
		for _, i := range indices {
			withScope = append(withScope, occurrenceKeys[i])
			withoutScope = append(withoutScope, occurrenceKeysWithoutScope[i])
			if parents[i] < 0 {
				roots = append(roots, i)
			}
		}
		if len(roots) == 0 {
			continue
		}
		sort.Strings(withScope)
		sort.Strings(withoutScope)
		rootSet := digest([]byte(canonical(withScope)))[:12]
		rootSetWithoutScope := digest([]byte(canonical(withoutScope)))[:12]
		for _, i := range roots {
			d.Spans[i].TraceRoots = rootSet
			d.Spans[i].TraceRootsWithoutScope = rootSetWithoutScope
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
		if len(roots) != 1 {
			coverage = "partial"
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
