package report

import (
	"encoding/hex"
	"fmt"
	"strconv"
	"strings"
	"unicode"
)

type sexpr struct {
	atom string
	list []sexpr
	str  bool
}

func unquote(expr sexpr) sexpr {
	if len(expr.list) == 2 && head(expr) == "quote" {
		return expr.list[1]
	}
	return expr
}

func validateImmutableSource(href string) error {
	if !strings.HasPrefix(href, "https://") {
		return fmt.Errorf("source evidence must use https")
	}
	lower := strings.ToLower(href)
	for _, mutable := range []string{"/main/", "/master/", "/head/", "/latest/"} {
		if strings.Contains(lower, mutable) {
			return fmt.Errorf("source evidence URL is mutable: %q", href)
		}
	}
	if strings.Contains(lower, "github.com/") {
		marker := "/blob/"
		if !strings.Contains(lower, marker) {
			marker = "/tree/"
		}
		parts := strings.SplitN(lower, marker, 2)
		if len(parts) != 2 {
			return fmt.Errorf("GitHub source evidence must use a commit-pinned blob or tree URL: %q", href)
		}
		revision := strings.SplitN(parts[1], "/", 2)[0]
		if len(revision) != 40 {
			return fmt.Errorf("GitHub source evidence revision is not a 40-character commit: %q", href)
		}
		if _, err := hex.DecodeString(revision); err != nil {
			return fmt.Errorf("GitHub source evidence revision is not hexadecimal: %q", href)
		}
	}
	return nil
}

func stringSliceContains(values []string, wanted string) bool {
	for _, value := range values {
		if value == wanted {
			return true
		}
	}
	return false
}

func ParseScenarioShape(profile, scenario, source, input string) (ScenarioShape, error) {
	tokens, err := tokenizeScheme(input)
	if err != nil {
		return ScenarioShape{}, fmt.Errorf("%s: %w", source, err)
	}
	forms, err := parseScheme(tokens)
	if err != nil {
		return ScenarioShape{}, fmt.Errorf("%s: %w", source, err)
	}
	var value *sexpr
	for i := range forms {
		if found := findDefinition(&forms[i], "scenario-shape"); found != nil {
			value = found
			break
		}
	}
	if value == nil {
		return ScenarioShape{}, fmt.Errorf("%s: missing scenario-shape definition", source)
	}
	if head(*value) != "traces" {
		return ScenarioShape{}, fmt.Errorf("%s: expected trace shapes must use traces", source)
	}
	shape := ScenarioShape{Profile: profile, Scenario: scenario, Source: source, ExactCounts: true, Scopes: map[string]int{}, Statuses: map[string]int{}}
	for _, item := range value.list[1:] {
		trace, err := parseTraceGroup(item)
		if err != nil {
			return ScenarioShape{}, fmt.Errorf("%s: %w", source, err)
		}
		shape.Traces = append(shape.Traces, trace)
		shape.ExactCounts = shape.ExactCounts && trace.ExactCount
	}
	if len(shape.Traces) == 0 {
		return ScenarioShape{}, fmt.Errorf("%s: shape contains no traces", source)
	}
	if shape.ExactCounts {
		for _, trace := range shape.Traces {
			shape.TraceCount += trace.Count
			for _, root := range trace.Roots {
				if !accumulateSpan(root, trace.Count, &shape) {
					shape.ExactCounts = false
					break
				}
			}
			if !shape.ExactCounts {
				break
			}
		}
	}
	if !shape.ExactCounts {
		shape.TraceCount, shape.SpanCount = 0, 0
		shape.Scopes, shape.Statuses = map[string]int{}, map[string]int{}
	}
	return shape, nil
}

func parseTraceGroup(expr sexpr) (TraceGroup, error) {
	switch head(expr) {
	case "trace":
		trace, err := parseTrace(expr)
		if err != nil {
			return TraceGroup{}, err
		}
		trace.Count, trace.MinCount, trace.MaxCount, trace.ExactCount = 1, 1, 1, true
		return trace, nil
	case "repeat", "between", "optional":
		minimum, maximum, value, err := parseCardinality(expr)
		if err != nil {
			return TraceGroup{}, err
		}
		group, err := parseTraceGroup(value)
		if err != nil {
			return TraceGroup{}, err
		}
		return applyTraceCardinality(group, head(expr), minimum, maximum), nil
	case "one-of":
		if len(expr.list) < 2 {
			return TraceGroup{}, fmt.Errorf("one-of trace requires an alternative")
		}
		group := TraceGroup{Cardinality: "one_of"}
		for _, value := range expr.list[1:] {
			alternative, err := parseTraceGroup(value)
			if err != nil {
				return TraceGroup{}, err
			}
			group.Alternatives = append(group.Alternatives, alternative)
			minimum, maximum := traceBounds(alternative)
			if len(group.Alternatives) == 1 || minimum < group.MinCount {
				group.MinCount = minimum
			}
			if maximum > group.MaxCount {
				group.MaxCount = maximum
			}
		}
		return group, nil
	default:
		return TraceGroup{}, fmt.Errorf("expected trace or trace cardinality, got %s", head(expr))
	}
}

func parseTrace(expr sexpr) (TraceGroup, error) {
	trace := TraceGroup{Count: 1}
	for _, property := range expr.list[1:] {
		switch head(property) {
		case "coverage":
			if len(property.list) != 2 {
				return trace, fmt.Errorf("invalid coverage expression")
			}
			trace.Coverage = atomValue(property.list[1])
		case "unordered":
			for _, item := range property.list[1:] {
				group, err := parseSpanGroup(item)
				if err != nil {
					return trace, err
				}
				trace.Roots = append(trace.Roots, group)
			}
		}
	}
	if trace.Coverage == "" {
		trace.Coverage = "unknown"
	}
	if len(trace.Roots) == 0 {
		return trace, fmt.Errorf("trace has no root spans")
	}
	return trace, nil
}

func parseSpanGroup(expr sexpr) (SpanGroup, error) {
	switch head(expr) {
	case "span":
		span, err := parseSpan(expr)
		if err != nil {
			return SpanGroup{}, err
		}
		return SpanGroup{Count: 1, ExactCount: true, MinCount: 1, MaxCount: 1, Span: span}, nil
	case "repeat", "between", "optional":
		minimum, maximum, value, err := parseCardinality(expr)
		if err != nil {
			return SpanGroup{}, err
		}
		group, err := parseSpanGroup(value)
		if err != nil {
			return SpanGroup{}, err
		}
		return applySpanCardinality(group, head(expr), minimum, maximum), nil
	case "one-of":
		if len(expr.list) < 2 {
			return SpanGroup{}, fmt.Errorf("one-of span requires an alternative")
		}
		group := SpanGroup{Cardinality: "one_of"}
		for _, value := range expr.list[1:] {
			alternative, err := parseSpanGroup(value)
			if err != nil {
				return SpanGroup{}, err
			}
			group.Alternatives = append(group.Alternatives, alternative)
			minimum, maximum := spanBounds(alternative)
			if len(group.Alternatives) == 1 || minimum < group.MinCount {
				group.MinCount = minimum
			}
			if maximum > group.MaxCount {
				group.MaxCount = maximum
			}
		}
		return group, nil
	default:
		return SpanGroup{}, fmt.Errorf("expected span or span cardinality, got %s", head(expr))
	}
}

func parseSpan(expr sexpr) (SpanNode, error) {
	span := SpanNode{}
	for _, property := range expr.list[1:] {
		switch head(property) {
		case "scope":
			span.Scope = secondValue(property)
		case "kind":
			span.Kind = secondValue(property)
		case "status":
			span.Status = secondValue(property)
		case "http-status":
			span.HTTPStatus = secondValue(property)
		case "name":
			if len(property.list) > 1 {
				span.Name = renderMatcher(property.list[1])
			}
		case "children":
			if len(property.list) != 2 || head(property.list[1]) != "unordered" {
				return span, fmt.Errorf("span children must be unordered")
			}
			for _, item := range property.list[1].list[1:] {
				child, err := parseSpanGroup(item)
				if err != nil {
					return span, err
				}
				span.Children = append(span.Children, child)
			}
		}
	}
	return span, nil
}

func parseCardinality(expr sexpr) (int, int, sexpr, error) {
	parseCount := func(value sexpr) (int, error) {
		count, err := strconv.Atoi(atomValue(value))
		if err != nil || count < 0 {
			return 0, fmt.Errorf("invalid %s count", head(expr))
		}
		return count, nil
	}
	switch head(expr) {
	case "repeat":
		if len(expr.list) != 3 {
			return 0, 0, sexpr{}, fmt.Errorf("repeat requires count and value")
		}
		count, err := parseCount(expr.list[1])
		return count, count, expr.list[2], err
	case "between":
		if len(expr.list) != 4 {
			return 0, 0, sexpr{}, fmt.Errorf("between requires minimum, maximum, and value")
		}
		minimum, err := parseCount(expr.list[1])
		if err != nil {
			return 0, 0, sexpr{}, err
		}
		maximum, err := parseCount(expr.list[2])
		if err != nil || maximum < minimum {
			return 0, 0, sexpr{}, fmt.Errorf("invalid between range")
		}
		return minimum, maximum, expr.list[3], nil
	case "optional":
		if len(expr.list) != 2 {
			return 0, 0, sexpr{}, fmt.Errorf("optional requires a value")
		}
		return 0, 1, expr.list[1], nil
	default:
		return 0, 0, sexpr{}, fmt.Errorf("unsupported cardinality %s", head(expr))
	}
}

func applyTraceCardinality(group TraceGroup, cardinality string, minimum, maximum int) TraceGroup {
	groupMinimum, groupMaximum := traceBounds(group)
	if len(group.Alternatives) == 0 {
		group.MinCount, group.MaxCount = minimum*groupMinimum, maximum*groupMaximum
		group.ExactCount = minimum == maximum && group.ExactCount
		if group.ExactCount {
			group.Count = group.MinCount
		} else {
			group.Count, group.Cardinality = 0, cardinality
		}
		return group
	}
	return TraceGroup{
		Cardinality:  cardinality,
		MinCount:     minimum * groupMinimum,
		MaxCount:     maximum * groupMaximum,
		Alternatives: []TraceGroup{group},
	}
}

func applySpanCardinality(group SpanGroup, cardinality string, minimum, maximum int) SpanGroup {
	groupMinimum, groupMaximum := spanBounds(group)
	if len(group.Alternatives) == 0 {
		group.MinCount, group.MaxCount = minimum*groupMinimum, maximum*groupMaximum
		group.ExactCount = minimum == maximum && group.ExactCount
		if group.ExactCount {
			group.Count = group.MinCount
		} else {
			group.Count, group.Cardinality = 0, cardinality
		}
		return group
	}
	return SpanGroup{
		Cardinality:  cardinality,
		MinCount:     minimum * groupMinimum,
		MaxCount:     maximum * groupMaximum,
		Alternatives: []SpanGroup{group},
	}
}

func traceBounds(group TraceGroup) (int, int) {
	if group.ExactCount {
		return group.Count, group.Count
	}
	return group.MinCount, group.MaxCount
}

func spanBounds(group SpanGroup) (int, int) {
	if group.ExactCount {
		return group.Count, group.Count
	}
	return group.MinCount, group.MaxCount
}

func accumulateSpan(group SpanGroup, parentMultiplier int, shape *ScenarioShape) bool {
	if !group.ExactCount || len(group.Alternatives) != 0 {
		return false
	}
	multiplier := parentMultiplier * group.Count
	shape.SpanCount += multiplier
	if group.Span.Scope != "" {
		shape.Scopes[group.Span.Scope] += multiplier
	}
	if group.Span.Status != "" {
		shape.Statuses[group.Span.Status] += multiplier
	}
	for _, child := range group.Span.Children {
		if !accumulateSpan(child, multiplier, shape) {
			return false
		}
	}
	return true
}

func renderMatcher(expr sexpr) string {
	if len(expr.list) == 0 {
		return atomValue(expr)
	}
	values := make([]string, 0, len(expr.list)-1)
	for _, item := range expr.list[1:] {
		values = append(values, renderMatcher(item))
	}
	if len(values) == 0 {
		return head(expr)
	}
	switch head(expr) {
	case "exact":
		return values[0]
	case "one-of":
		return "one of: " + strings.Join(values, " | ")
	case "prefix-suffix":
		return strings.Join(values, " … ")
	default:
		return head(expr) + ": " + strings.Join(values, " … ")
	}
}

func secondValue(expr sexpr) string {
	if len(expr.list) < 2 {
		return ""
	}
	return atomValue(expr.list[1])
}

func atomValue(expr sexpr) string {
	if len(expr.list) == 2 && head(expr) == "quote" {
		return atomValue(expr.list[1])
	}
	if len(expr.list) == 0 {
		return expr.atom
	}
	return head(expr)
}

func head(expr sexpr) string {
	if len(expr.list) == 0 {
		return ""
	}
	return atomValue(expr.list[0])
}

func findDefinition(expr *sexpr, name string) *sexpr {
	if head(*expr) == "define" && len(expr.list) >= 3 && atomValue(expr.list[1]) == name {
		return &expr.list[2]
	}
	for i := range expr.list {
		if found := findDefinition(&expr.list[i], name); found != nil {
			return found
		}
	}
	return nil
}

func tokenizeScheme(input string) ([]sexpr, error) {
	var tokens []sexpr
	runes := []rune(input)
	for i := 0; i < len(runes); {
		switch {
		case unicode.IsSpace(runes[i]):
			i++
		case runes[i] == ';':
			for i < len(runes) && runes[i] != '\n' {
				i++
			}
		case runes[i] == '(' || runes[i] == ')' || runes[i] == '\'':
			tokens = append(tokens, sexpr{atom: string(runes[i])})
			i++
		case runes[i] == '"':
			i++
			var value strings.Builder
			closed := false
			for i < len(runes) {
				if runes[i] == '"' {
					i++
					closed = true
					break
				}
				if runes[i] == '\\' && i+1 < len(runes) {
					i++
					switch runes[i] {
					case 'n':
						value.WriteRune('\n')
					case 'r':
						value.WriteRune('\r')
					case 't':
						value.WriteRune('\t')
					default:
						value.WriteRune(runes[i])
					}
					i++
					continue
				}
				value.WriteRune(runes[i])
				i++
			}
			if !closed {
				return nil, fmt.Errorf("unterminated string")
			}
			tokens = append(tokens, sexpr{atom: value.String(), str: true})
		default:
			start := i
			for i < len(runes) && !unicode.IsSpace(runes[i]) && !strings.ContainsRune("()'\";", runes[i]) {
				i++
			}
			tokens = append(tokens, sexpr{atom: string(runes[start:i])})
		}
	}
	return tokens, nil
}

func parseScheme(tokens []sexpr) ([]sexpr, error) {
	position := 0
	var parseOne func() (sexpr, error)
	parseOne = func() (sexpr, error) {
		if position >= len(tokens) {
			return sexpr{}, fmt.Errorf("unexpected end of input")
		}
		token := tokens[position]
		position++
		switch token.atom {
		case "(":
			var list []sexpr
			for position < len(tokens) && tokens[position].atom != ")" {
				item, err := parseOne()
				if err != nil {
					return sexpr{}, err
				}
				list = append(list, item)
			}
			if position >= len(tokens) {
				return sexpr{}, fmt.Errorf("unclosed list")
			}
			position++
			return sexpr{list: list}, nil
		case ")":
			return sexpr{}, fmt.Errorf("unexpected closing parenthesis")
		case "'":
			item, err := parseOne()
			if err != nil {
				return sexpr{}, err
			}
			return sexpr{list: []sexpr{{atom: "quote"}, item}}, nil
		default:
			return token, nil
		}
	}
	var forms []sexpr
	for position < len(tokens) {
		item, err := parseOne()
		if err != nil {
			return nil, err
		}
		forms = append(forms, item)
	}
	return forms, nil
}
