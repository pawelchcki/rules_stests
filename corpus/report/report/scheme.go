package report

import (
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

func ParseGolden(profile, scenario, source, input string) (Golden, error) {
	tokens, err := tokenizeScheme(input)
	if err != nil {
		return Golden{}, fmt.Errorf("%s: %w", source, err)
	}
	forms, err := parseScheme(tokens)
	if err != nil {
		return Golden{}, fmt.Errorf("%s: %w", source, err)
	}
	var value *sexpr
	for i := range forms {
		if found := findDefinition(&forms[i], "expected-trace-shapes"); found != nil {
			value = found
			break
		}
	}
	if value == nil {
		return Golden{}, fmt.Errorf("%s: missing expected-trace-shapes definition", source)
	}
	if head(*value) != "traces" {
		return Golden{}, fmt.Errorf("%s: expected trace shapes must use traces", source)
	}
	golden := Golden{Profile: profile, Scenario: scenario, Source: source, Scopes: map[string]int{}, Statuses: map[string]int{}}
	for _, item := range value.list[1:] {
		count, traceExpr, err := unwrapRepeat(item, "trace")
		if err != nil {
			return Golden{}, fmt.Errorf("%s: %w", source, err)
		}
		trace, err := parseTrace(traceExpr)
		if err != nil {
			return Golden{}, fmt.Errorf("%s: %w", source, err)
		}
		trace.Count = count
		golden.Traces = append(golden.Traces, trace)
		golden.TraceCount += count
		for _, root := range trace.Roots {
			accumulateSpan(root, count, &golden)
		}
	}
	if golden.TraceCount == 0 {
		return Golden{}, fmt.Errorf("%s: golden contains no traces", source)
	}
	return golden, nil
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
	count, spanExpr, err := unwrapRepeat(expr, "span")
	if err != nil {
		return SpanGroup{}, err
	}
	span, err := parseSpan(spanExpr)
	if err != nil {
		return SpanGroup{}, err
	}
	return SpanGroup{Count: count, Span: span}, nil
}

func parseSpan(expr sexpr) (SpanNode, error) {
	span := SpanNode{HTTPStatus: "absent"}
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
	if span.Scope == "" || span.Kind == "" || span.Status == "" || span.Name == "" {
		return span, fmt.Errorf("span is missing scope, kind, status, or name")
	}
	return span, nil
}

func unwrapRepeat(expr sexpr, wanted string) (int, sexpr, error) {
	if head(expr) == wanted {
		return 1, expr, nil
	}
	if head(expr) != "repeat" || len(expr.list) != 3 || head(expr.list[2]) != wanted {
		return 0, sexpr{}, fmt.Errorf("expected %s or repeat %s", wanted, wanted)
	}
	count, err := strconv.Atoi(atomValue(expr.list[1]))
	if err != nil || count < 1 {
		return 0, sexpr{}, fmt.Errorf("invalid repeat count")
	}
	return count, expr.list[2], nil
}

func accumulateSpan(group SpanGroup, parentMultiplier int, golden *Golden) {
	multiplier := parentMultiplier * group.Count
	golden.SpanCount += multiplier
	golden.Scopes[group.Span.Scope] += multiplier
	golden.Statuses[group.Span.Status] += multiplier
	for _, child := range group.Span.Children {
		accumulateSpan(child, multiplier, golden)
	}
}

func renderMatcher(expr sexpr) string {
	if len(expr.list) == 0 {
		return atomValue(expr)
	}
	values := make([]string, 0, len(expr.list)-1)
	for _, item := range expr.list[1:] {
		values = append(values, atomValue(item))
	}
	if len(values) == 0 {
		return head(expr)
	}
	if head(expr) == "exact" {
		return values[0]
	}
	return head(expr) + ": " + strings.Join(values, " … ")
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
