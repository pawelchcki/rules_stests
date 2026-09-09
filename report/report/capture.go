package report

import (
	"bytes"
	"encoding/base64"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"io"
	"math"
	"math/big"
	"regexp"
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
func normalizeWire(v any, encoding string) (any, error) {
	return normalizeWireContext(v, "tracePayload", encoding)
}

var allowedWireFields = map[string][]string{
	"tracePayload": {"resourceSpans"},
	"resourceSpan": {"resource", "scopeSpans", "schemaUrl"},
	"resource":     {"attributes", "droppedAttributesCount", "entityRefs"},
	"entityRef":    {"schemaUrl", "type", "idKeys", "descriptionKeys"},
	"scopeSpan":    {"scope", "spans", "schemaUrl"},
	"scope":        {"name", "version", "attributes", "droppedAttributesCount"},
	"span":         {"traceId", "spanId", "traceState", "parentSpanId", "name", "kind", "startTimeUnixNano", "endTimeUnixNano", "attributes", "droppedAttributesCount", "events", "droppedEventsCount", "links", "droppedLinksCount", "status", "flags"},
	"spanEvent":    {"timeUnixNano", "name", "attributes", "droppedAttributesCount"},
	"spanLink":     {"traceId", "spanId", "traceState", "attributes", "droppedAttributesCount", "flags"},
	"status":       {"message", "code"},
	"keyValue":     {"key", "value"},
	"anyValue":     {"value", "stringValue", "boolValue", "intValue", "doubleValue", "arrayValue", "kvlistValue", "bytesValue"},
	"arrayValue":   {"values"},
	"keyValueList": {"values"},
}

func allowedWireField(context, key string) bool {
	fields := allowedWireFields[context]
	if fields == nil {
		return true
	}
	for _, field := range fields {
		if key == field {
			return true
		}
	}
	return false
}

func snakeWireField(field string) string {
	var out strings.Builder
	for _, character := range field {
		if character >= 'A' && character <= 'Z' {
			out.WriteByte('_')
			character += 'a' - 'A'
		}
		out.WriteRune(character)
	}
	return out.String()
}

func canonicalWireField(context, spelling string) (string, bool) {
	fields, known := allowedWireFields[context]
	if !known {
		return spelling, true
	}
	for _, field := range fields {
		if spelling == field || spelling == snakeWireField(field) {
			return field, true
		}
	}
	return "", false
}

func protocolStringField(context, key string) bool {
	switch context {
	case "resourceSpan", "scopeSpan":
		return key == "schemaUrl"
	case "entityRef":
		return key == "schemaUrl" || key == "type"
	case "scope":
		return key == "name" || key == "version"
	case "span":
		return key == "traceState" || key == "name"
	case "spanEvent":
		return key == "name"
	case "spanLink":
		return key == "traceState"
	case "status":
		return key == "message"
	case "keyValue":
		return key == "key"
	}
	return false
}

func protocolArrayField(context, key string) bool {
	switch context {
	case "tracePayload":
		return key == "resourceSpans"
	case "resourceSpan":
		return key == "scopeSpans"
	case "resource":
		return key == "attributes" || key == "entityRefs"
	case "scopeSpan":
		return key == "spans"
	case "scope", "spanEvent", "spanLink":
		return key == "attributes"
	case "span":
		return key == "attributes" || key == "events" || key == "links"
	case "arrayValue", "keyValueList":
		return key == "values"
	}
	return false
}

func protocolUint32Field(context, key string) bool {
	if key == "droppedAttributesCount" {
		return context == "resource" || context == "scope" || context == "span" || context == "spanEvent" || context == "spanLink"
	}
	if context == "span" {
		return key == "flags" || key == "droppedEventsCount" || key == "droppedLinksCount"
	}
	return context == "spanLink" && key == "flags"
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

var decimalFloat = regexp.MustCompile(`^[+-]?(?:[0-9]+(?:\.[0-9]*)?|\.[0-9]+)(?:[eE][+-]?[0-9]+)?$`)

func normalizeWireContext(v any, context, encoding string) (any, error) {
	switch v := v.(type) {
	case json.Number:
		if context == "identity" {
			return v, nil
		}
		return v.String(), nil
	case []any:
		out := make([]any, len(v))
		childContext := ""
		switch context {
		case "resourceSpans":
			childContext = "resourceSpan"
		case "scopeSpans":
			childContext = "scopeSpan"
		case "spans":
			childContext = "span"
		case "events":
			childContext = "spanEvent"
		case "links":
			childContext = "spanLink"
		case "entityRefs":
			childContext = "entityRef"
		case "anyValues":
			childContext = "anyValue"
		case "keyValues":
			childContext = "keyValue"
		}
		for i, c := range v {
			if childContext != "" {
				if _, ok := c.(map[string]any); !ok {
					return nil, fmt.Errorf("invalid OTLP %s element: expected object", context)
				}
			}
			var err error
			out[i], err = normalizeWireContext(c, childContext, encoding)
			if err != nil {
				return nil, err
			}
		}
		return out, nil
	case map[string]any:
		out := map[string]any{}
		for k, c := range v {
			key, validSpelling := canonicalWireField(context, k)
			if !validSpelling {
				return nil, fmt.Errorf("invalid OTLP %s field %q", context, k)
			}
			if _, exists := out[key]; exists {
				return nil, fmt.Errorf("duplicate OTLP JSON field spellings for %q", key)
			}
			childContext := ""
			switch {
			case context == "tracePayload" && key == "resourceSpans":
				childContext = "resourceSpans"
			case context == "resourceSpan" && key == "resource":
				childContext = "resource"
			case context == "resourceSpan" && key == "scopeSpans":
				childContext = "scopeSpans"
			case context == "resource" && key == "entityRefs":
				childContext = "entityRefs"
			case context == "entityRef" && (key == "idKeys" || key == "descriptionKeys"):
				childContext = key
			case context == "scopeSpan" && key == "scope":
				childContext = "scope"
			case context == "scopeSpan" && key == "spans":
				childContext = "spans"
			case context == "span" && key == "events":
				childContext = "events"
			case context == "span" && key == "links":
				childContext = "links"
			case context == "span" && key == "status":
				childContext = "status"
			case key == "traceId" || key == "spanId" || key == "parentSpanId":
				childContext = "identity"
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
			if !allowedWireField(context, key) || (context == "anyValue" && key == "value" && encoding != "protobuf") {
				return nil, fmt.Errorf("invalid OTLP %s field %q", context, key)
			}
			if encoding == "json" && ((context == "span" && key == "kind") || (context == "status" && key == "code")) && c != nil {
				if _, ok := c.(json.Number); !ok {
					return nil, fmt.Errorf("invalid OTLP %s field %q: expected integer enum", context, key)
				}
			}
			if c != nil && protocolStringField(context, key) {
				if _, ok := c.(string); !ok {
					return nil, fmt.Errorf("invalid OTLP %s field %q: expected string", context, key)
				}
			}
			if c != nil && protocolArrayField(context, key) {
				if _, ok := c.([]any); !ok {
					return nil, fmt.Errorf("invalid OTLP %s field %q: expected array", context, key)
				}
			}
			if c != nil && protocolUint32Field(context, key) {
				number, ok := c.(json.Number)
				if !ok {
					return nil, fmt.Errorf("invalid OTLP %s field %q: expected uint32", context, key)
				}
				if _, err := strconv.ParseUint(number.String(), 10, 32); err != nil {
					return nil, fmt.Errorf("invalid OTLP %s field %q: expected uint32", context, key)
				}
			}
			if c != nil {
				expectsObject := (context == "resourceSpan" && key == "resource") || (context == "scopeSpan" && key == "scope") || (context == "span" && key == "status") || (context == "keyValue" && key == "value")
				if expectsObject {
					if _, ok := c.(map[string]any); !ok {
						return nil, fmt.Errorf("invalid OTLP %s field %q: expected object", context, key)
					}
				}
			}
			if context == "anyValue" && c != nil {
				valid := true
				switch key {
				case "stringValue":
					_, valid = c.(string)
				case "boolValue":
					_, valid = c.(bool)
				case "arrayValue", "kvlistValue":
					_, valid = c.(map[string]any)
				case "bytesValue":
					_, stringValue := c.(string)
					_, arrayValue := c.([]any)
					valid = stringValue || (encoding == "protobuf" && arrayValue)
				}
				if !valid {
					return nil, fmt.Errorf("invalid OTLP AnyValue variant %q: unexpected JSON type", key)
				}
			}
			value, err := normalizeWireContext(c, childContext, encoding)
			if err != nil {
				return nil, err
			}
			out[key] = value
		}
		// prost's AnyValue wraps the oneof in an additional `value` object.
		// Restrict this unwrapping to known AnyValue positions: an omitted
		// KeyValue.key otherwise has the same single-field wire shape.
		if context == "anyValue" {
			if len(out) == 1 {
				if value, exists := out["value"]; exists && value == nil {
					return map[string]any{}, nil
				}
				if inner := object(out["value"]); inner != nil {
					for k := range inner {
						if strings.HasSuffix(k, "Value") {
							return inner, nil
						}
					}
				}
			}
			populated := 0
			for _, key := range []string{"stringValue", "boolValue", "intValue", "doubleValue", "arrayValue", "kvlistValue", "bytesValue"} {
				if value, exists := out[key]; exists {
					if value == nil {
						delete(out, key)
					} else {
						populated++
					}
				}
			}
			if populated > 1 {
				return nil, fmt.Errorf("invalid OTLP AnyValue: expected at most one variant, got %d", populated)
			}
		}
		if context == "keyValue" {
			if value, exists := out["value"]; exists && value == nil {
				delete(out, "value")
			}
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
			scalar := str(value)
			if scalar == "NaN" || scalar == "Infinity" || scalar == "-Infinity" {
				out["doubleValue"] = scalar
			} else {
				if !decimalFloat.MatchString(scalar) {
					return nil, fmt.Errorf("invalid OTLP double AnyValue")
				}
				number, err := strconv.ParseFloat(scalar, 64)
				if err != nil || math.IsNaN(number) || math.IsInf(number, 0) {
					return nil, fmt.Errorf("invalid OTLP double AnyValue")
				}
				out["doubleValue"] = strconv.FormatFloat(number, 'g', -1, 64)
			}
		}
		if value, ok := out["intValue"]; ok {
			number, err := strconv.ParseInt(str(value), 10, 64)
			if err != nil {
				return nil, fmt.Errorf("invalid OTLP integer AnyValue")
			}
			out["intValue"] = strconv.FormatInt(number, 10)
		}
		if b := array(out["bytesValue"]); b != nil {
			raw := make([]byte, len(b))
			for i, x := range b {
				n, err := strconv.ParseUint(str(x), 10, 8)
				if err != nil {
					return nil, fmt.Errorf("invalid OTLP bytes AnyValue")
				}
				raw[i] = byte(n)
			}
			out["bytesValue"] = base64.StdEncoding.EncodeToString(raw)
		} else if value, ok := out["bytesValue"].(string); ok {
			canonical, valid := canonicalBytes(value)
			if !valid {
				return nil, fmt.Errorf("invalid OTLP bytes AnyValue")
			}
			out["bytesValue"] = canonical
		}
		return out, nil
	default:
		return v, nil
	}
}
func enumValue(v any, prefix string, names []string) (string, bool) {
	s := str(v)
	if n, e := strconv.Atoi(s); e == nil {
		if n >= 0 && n < len(names) {
			return names[n], true
		}
		return "", false
	}
	s = strings.ToLower(strings.TrimPrefix(s, prefix))
	if s == "" {
		return names[0], true
	}
	for _, name := range names {
		if s == name {
			return name, true
		}
	}
	return "", false
}
func identity(v any, width int, optional bool) (string, error) {
	s, ok := v.(string)
	if !ok {
		return "", fmt.Errorf("invalid trace/span identity %q", str(v))
	}
	s = strings.ToLower(s)
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

const maxJSONValueNodes = 16 * 1024

func decodeUniqueJSON(decoder *json.Decoder) (any, error) {
	token, err := decoder.Token()
	if err != nil {
		return nil, err
	}
	delimiter, composite := token.(json.Delim)
	if !composite {
		return token, nil
	}
	switch delimiter {
	case '[':
		values := []any{}
		for decoder.More() {
			value, err := decodeUniqueJSON(decoder)
			if err != nil {
				return nil, err
			}
			values = append(values, value)
		}
		if _, err := decoder.Token(); err != nil {
			return nil, err
		}
		return values, nil
	case '{':
		values := map[string]any{}
		for decoder.More() {
			keyToken, err := decoder.Token()
			if err != nil {
				return nil, err
			}
			key, ok := keyToken.(string)
			if !ok {
				return nil, fmt.Errorf("invalid JSON object key")
			}
			if _, exists := values[key]; exists {
				return nil, fmt.Errorf("duplicate JSON key %q", key)
			}
			value, err := decodeUniqueJSON(decoder)
			if err != nil {
				return nil, err
			}
			values[key] = value
		}
		if _, err := decoder.Token(); err != nil {
			return nil, err
		}
		return values, nil
	default:
		return nil, fmt.Errorf("unexpected JSON delimiter %q", delimiter)
	}
}

func withinJSONNodeLimit(value any) bool {
	nodes := 0
	stack := []any{value}
	for len(stack) > 0 {
		value = stack[len(stack)-1]
		stack = stack[:len(stack)-1]
		nodes++
		if nodes > maxJSONValueNodes {
			return false
		}
		switch value := value.(type) {
		case []any:
			stack = append(stack, value...)
		case map[string]any:
			for _, child := range value {
				stack = append(stack, child)
			}
		}
	}
	return true
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
	value, decodeErr := decodeUniqueJSON(decoder)
	if decodeErr != nil {
		return fail(fmt.Errorf("unreadable trace capture: %w", decodeErr))
	}
	records, ok := value.([]any)
	if !ok {
		return fail(fmt.Errorf("unreadable trace capture: expected array"))
	}
	if _, err := decoder.Token(); err != io.EOF {
		return fail(fmt.Errorf("trailing capture data"))
	}
	maxSpanTimestamp := new(big.Int).SetUint64(^uint64(0))
	for _, record := range records {
		r := object(record)
		if str(r["signal"]) != "traces" {
			continue
		}
		encoding := str(r["encoding"])
		if encoding == "json" && !withinJSONNodeLimit(r["payload"]) {
			return fail(fmt.Errorf("JSON value exceeds structural limit of %d nodes", maxJSONValueNodes))
		}
		normalized, err := normalizeWire(r["payload"], encoding)
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
					name, ok := fields["name"].(string)
					if !ok {
						return fail(fmt.Errorf("invalid span name"))
					}
					if name == "" {
						return fail(fmt.Errorf("span has no name"))
					}
					start, validStart := new(big.Int).SetString(str(fields["startTimeUnixNano"]), 10)
					end, validEnd := new(big.Int).SetString(str(fields["endTimeUnixNano"]), 10)
					if !validStart || start.Cmp(maxSpanTimestamp) > 0 {
						return fail(fmt.Errorf("invalid span start timestamp"))
					}
					if !validEnd || end.Cmp(maxSpanTimestamp) > 0 {
						return fail(fmt.Errorf("invalid span end timestamp"))
					}
					if start.Sign() <= 0 || end.Cmp(start) < 0 {
						return fail(fmt.Errorf("span timestamps are not ordered"))
					}
					attributes, err := repeatedField(fields["attributes"], "span attributes")
					if err != nil {
						return fail(err)
					}
					events, err := repeatedField(fields["events"], "span events")
					if err != nil {
						return fail(err)
					}
					links, err := repeatedField(fields["links"], "span links")
					if err != nil {
						return fail(err)
					}
					fields["attributes"], fields["events"], fields["links"] = attributes, events, links
					kind, validKind := enumValue(fields["kind"], "SPAN_KIND_", []string{"unspecified", "internal", "server", "client", "producer", "consumer"})
					if !validKind {
						return fail(fmt.Errorf("invalid span kind %v", fields["kind"]))
					}
					fields["kind"] = kind
					status := defaults(object(fields["status"]), map[string]any{"code": "0", "message": ""})
					statusCode, validStatus := enumValue(status["code"], "STATUS_CODE_", []string{"unset", "ok", "error"})
					if !validStatus {
						return fail(fmt.Errorf("invalid span status %v", status["code"]))
					}
					status["code"] = statusCode
					fields["status"] = status
					for _, event := range events {
						eventFields := object(event)
						if eventFields == nil {
							return fail(fmt.Errorf("unreadable span event"))
						}
						defaults(eventFields, map[string]any{"timeUnixNano": "0", "name": "", "attributes": []any{}, "droppedAttributesCount": "0"})
						if _, err := repeatedField(eventFields["attributes"], "span event attributes"); err != nil {
							return fail(err)
						}
					}
					for _, link := range links {
						linkFields := object(link)
						if linkFields == nil {
							return fail(fmt.Errorf("unreadable span link"))
						}
						defaults(linkFields, map[string]any{"traceState": "", "attributes": []any{}, "droppedAttributesCount": "0", "flags": "0"})
						if _, err := repeatedField(linkFields["attributes"], "span link attributes"); err != nil {
							return fail(err)
						}
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
	explicitRoots := map[string]int{}
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
		if parentIDs[i] == "" {
			explicitRoots[traceIDs[i]]++
			if explicitRoots[traceIDs[i]] > 1 {
				return fail(fmt.Errorf("trace %q has multiple explicit roots", traceIDs[i]))
			}
		}
		key := traceIDs[i] + "/" + spanIDs[i]
		if _, ok := ids[key]; ok {
			return fail(fmt.Errorf("duplicate span identity %s", key))
		}
		ids[key] = i
		traces[traceIDs[i]] = append(traces[traceIDs[i]], i)
	}
	externalParentAnchors := map[string]bool{}
	for i := range d.Spans {
		parents[i] = -1
		if parentIDs[i] != "" {
			if p, ok := ids[traceIDs[i]+"/"+parentIDs[i]]; ok {
				parents[i] = p
				children[p] = append(children[p], i)
			} else {
				externalParentAnchors[traceIDs[i]+"/"+parentIDs[i]] = true
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
		subtrees := make([]string, len(d.Spans))
		var subtree func(int) string
		subtree = func(i int) string {
			if subtrees[i] != "" {
				return subtrees[i]
			}
			descendants := make([]string, 0, len(children[i]))
			for _, child := range children[i] {
				descendants = append(descendants, subtree(child))
			}
			sort.Strings(descendants)
			subtrees[i] = digest([]byte(canonical([]any{semanticSpanProjection(&d, i, includeScope), descendants})))[:12]
			return subtrees[i]
		}
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
			keys[i] = digest([]byte(canonical([]any{parent, subtree(i)})))[:12]
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
				if externalParentAnchors[targetKey] {
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
		adjacent := make([]map[int]bool, len(d.Spans))
		for source := range edges {
			adjacent[source] = map[int]bool{}
			for _, edge := range edges[source] {
				if edge.target >= 0 {
					adjacent[source][edge.target] = true
				}
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
			rootedCertificate := func(root int) any {
				visited := map[int]int{}
				var visit func(int) any
				visit = func(member int) any {
					if reference, ok := visited[member]; ok {
						return map[string]any{"reference": reference}
					}
					visited[member] = len(visited)
					outgoing := make([]any, 0, len(edges[member]))
					for _, edge := range edges[member] {
						descriptor := map[string]any{"relationship": edge.relationship}
						if edge.target < 0 {
							descriptor["externalTarget"] = externalLabels[edge.external]
						} else if componentOf[edge.target] == component {
							descriptor["target"] = visit(edge.target)
						} else {
							descriptor["target"] = keys[edge.target]
						}
						if edge.shared != "" {
							descriptor["sharedTarget"] = edge.shared
						}
						outgoing = append(outgoing, descriptor)
					}
					return map[string]any{"occurrence": base[member], "links": outgoing}
				}
				return visit(root)
			}
			// Small components retain a rooted certificate for every member.
			// Large components retain one complete adjacency certificate in
			// their shared label, avoiding the former per-root quadratic work.
			if len(components[component]) <= 64 {
				for _, root := range components[component] {
					keys[root] = digest([]byte(canonical(rootedCertificate(root))))[:12]
				}
				componentState[component] = 2
				return
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
						descriptor["componentTarget"] = map[string]any{"occurrence": base[edge.target], "reciprocal": adjacent[edge.target][member]}
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
			root := components[component][0]
			rootKey := canonical([]any{base[root], memberDescriptions[root]})
			rootCandidates := []int{root}
			for _, member := range components[component][1:] {
				candidate := canonical([]any{base[member], memberDescriptions[member]})
				if candidate < rootKey {
					root, rootKey = member, candidate
					rootCandidates = []int{member}
				} else if candidate == rootKey {
					rootCandidates = append(rootCandidates, member)
				}
			}
			// A uniform simple cycle is vertex-transitive, so every tied root
			// has the same complete certificate. Other ties need the exact
			// certificate to avoid falling back to capture/DFS order.
			uniformSimpleCycle := len(rootCandidates) == len(components[component])
			if uniformSimpleCycle {
				for _, member := range components[component] {
					internal := 0
					for _, edge := range edges[member] {
						if edge.target >= 0 && componentOf[edge.target] == component {
							internal++
						}
					}
					if internal != 1 {
						uniformSimpleCycle = false
						break
					}
				}
			}
			rooted := canonical(rootedCertificate(root))
			if len(rootCandidates) > 1 && !uniformSimpleCycle {
				for _, candidate := range rootCandidates[1:] {
					certificate := canonical(rootedCertificate(candidate))
					if certificate < rooted {
						root, rooted = candidate, certificate
					}
				}
			}
			adjacencyKey := digest([]byte(rooted))[:12]
			sort.Strings(descriptions)
			componentKeys[component] = digest([]byte(canonical([]any{descriptions, adjacencyKey})))[:12]
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
			if externalParentAnchors[tid+"/"+sid] {
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
	descendantPartitions := make([]string, len(d.Spans))
	var descendantPartition func(int) string
	descendantPartition = func(i int) string {
		if descendantPartitions[i] != "" {
			return descendantPartitions[i]
		}
		descendants := make([]string, 0, len(children[i]))
		for _, child := range children[i] {
			descendants = append(descendants, canonical([]any{semanticSpanProjection(&d, child, false), descendantPartition(child)}))
		}
		sort.Strings(descendants)
		descendantPartitions[i] = digest([]byte(canonical(descendants)))[:12]
		return descendantPartitions[i]
	}
	for i := range d.Spans {
		descendantPartition(i)
	}
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
		perTrace := map[string]map[string]int{}
		for _, i := range indices {
			if perTrace[fingerprints[i]] == nil {
				perTrace[fingerprints[i]] = map[string]int{}
			}
			perTrace[fingerprints[i]][traceIDs[i]]++
		}
		byKey := map[string][]int{}
		for _, i := range indices {
			key := fingerprints[i]
			if perTrace[fingerprints[i]][traceIDs[i]] > 1 {
				key += "\x00" + descendantPartitions[i]
			}
			byKey[key] = append(byKey[key], i)
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
