package report

import (
	"fmt"
	"regexp"
	"strings"
)

// Alignment pairs the traces and spans of two scenario shapes so a reader can
// see which spans exist on both sides, which differ, and which are unique to a
// single implementation. It renders no verdict: matching is purely structural.

var pathParameterPattern = regexp.MustCompile(`%?\{[^}]*\}|<[^>]*>|:[A-Za-z_][A-Za-z0-9_]*`)
var whitespacePattern = regexp.MustCompile(`\s+`)

// NormalizeSpanName lowercases a span name, drops a leading slash on the route
// portion, and rewrites path parameters to "*" so routes that differ only in
// the parameter syntax used by a framework still align.
func NormalizeSpanName(name string) string {
	normalized := strings.ToLower(strings.TrimSpace(name))
	normalized = pathParameterPattern.ReplaceAllString(normalized, "*")
	normalized = whitespacePattern.ReplaceAllString(normalized, " ")
	fields := strings.Split(normalized, " ")
	for i, field := range fields {
		if strings.HasPrefix(field, "/") && len(field) > 1 {
			fields[i] = strings.TrimPrefix(field, "/")
		}
	}
	return strings.Join(fields, " ")
}

type alignedSpan struct {
	node      SpanNode
	card      string
	minCount  int
	maxCount  int
	exact     bool
	altCount  int
	children  []alignedSpan
	keyString string
}

func spanKey(node SpanNode) string {
	return node.Kind + "\x00" + NormalizeSpanName(node.Name)
}

func rootKey(node SpanNode) string {
	return spanKey(node) + "\x00" + node.HTTPStatus
}

func formatCard(minCount, maxCount int, exact bool, altCount int) string {
	var card string
	switch {
	case exact && minCount == 1:
		card = ""
	case exact:
		card = fmt.Sprintf("×%d", minCount)
	case minCount == 0 && maxCount == 1:
		card = "optional"
	case minCount == maxCount:
		card = fmt.Sprintf("×%d", minCount)
	default:
		card = fmt.Sprintf("×%d–%d", minCount, maxCount)
	}
	if altCount > 1 {
		alternatives := fmt.Sprintf("one of %d", altCount)
		if card == "" {
			return alternatives
		}
		return alternatives + " · " + card
	}
	return card
}

// resolveSpanGroup expands one authored span group into the candidate spans it
// can produce. A group without alternatives yields exactly one candidate; a
// one-of group yields one candidate per alternative, each tagged with the
// number of alternatives so the front end can label the choice.
func resolveSpanGroup(group SpanGroup, opposite map[string]int) []alignedSpan {
	if len(group.Alternatives) > 0 {
		var candidates []alignedSpan
		for _, alternative := range group.Alternatives {
			for _, candidate := range resolveSpanGroup(alternative, opposite) {
				// A cardinality wrapper around a one-of holds a single
				// alternative; keep the inner choice count in that case.
				if len(group.Alternatives) > 1 {
					candidate.altCount = len(group.Alternatives)
				}
				if group.Cardinality != "" && group.Cardinality != "one_of" {
					candidate.minCount, candidate.maxCount, candidate.exact = group.MinCount, group.MaxCount, false
				}
				candidate.card = formatCard(candidate.minCount, candidate.maxCount, candidate.exact, candidate.altCount)
				candidates = append(candidates, candidate)
			}
		}
		return candidates
	}
	minCount, maxCount := spanBounds(group)
	span := alignedSpan{
		node:      group.Span,
		minCount:  minCount,
		maxCount:  maxCount,
		exact:     group.ExactCount,
		keyString: spanKey(group.Span),
	}
	span.card = formatCard(minCount, maxCount, group.ExactCount, 0)
	span.children = chooseCandidates(group.Span.Children, opposite)
	return []alignedSpan{span}
}

// subtreeKeys collects every span key in a candidate subtree so alternative
// selection can score candidates against the opposite side.
func subtreeKeys(spans []alignedSpan, into map[string]int) {
	for _, span := range spans {
		into[span.keyString]++
		subtreeKeys(span.children, into)
	}
}

// chooseCandidates picks, for each authored group, the candidate that shares
// the most span keys with the opposite side. Ties resolve to the first
// alternative, keeping the result deterministic.
func chooseCandidates(groups []SpanGroup, opposite map[string]int) []alignedSpan {
	var chosen []alignedSpan
	for _, group := range groups {
		candidates := resolveSpanGroup(group, opposite)
		if len(candidates) == 0 {
			continue
		}
		best, bestScore := candidates[0], -1
		for _, candidate := range candidates {
			keys := map[string]int{}
			subtreeKeys([]alignedSpan{candidate}, keys)
			score := 0
			for key, count := range keys {
				if available, ok := opposite[key]; ok {
					if count < available {
						score += count
					} else {
						score += available
					}
				}
			}
			if candidate.keyString != "" && opposite[candidate.keyString] > 0 {
				score += 100
			}
			if score > bestScore {
				best, bestScore = candidate, score
			}
		}
		chosen = append(chosen, best)
	}
	return chosen
}

func candidateKeys(groups []SpanGroup) map[string]int {
	keys := map[string]int{}
	for _, group := range groups {
		for _, candidate := range resolveSpanGroup(group, nil) {
			subtreeKeys([]alignedSpan{candidate}, keys)
		}
	}
	return keys
}

func spanRef(span alignedSpan) *SpanNode {
	node := span.node
	node.Children = nil
	return &node
}

func spanDiffs(left, right alignedSpan) []string {
	var diffs []string
	if left.card != right.card {
		diffs = append(diffs, "count")
	}
	if left.node.Name != right.node.Name {
		diffs = append(diffs, "name")
	}
	if left.node.Kind != right.node.Kind {
		diffs = append(diffs, "kind")
	}
	if left.node.Status != right.node.Status {
		diffs = append(diffs, "status")
	}
	if left.node.HTTPStatus != right.node.HTTPStatus {
		diffs = append(diffs, "httpStatus")
	}
	if left.node.Scope != right.node.Scope {
		diffs = append(diffs, "scope")
	}
	return diffs
}

// matchSpans pairs two sibling lists by span key and emits depth-annotated
// rows in a stable order: matched pairs first (in left order), then spans that
// exist only on the left, then spans only on the right.
func matchSpans(left, right []alignedSpan, depth int, summary *AlignSummary) []SpanMatch {
	rightByKey := map[string][]int{}
	for i, span := range right {
		rightByKey[span.keyString] = append(rightByKey[span.keyString], i)
	}
	usedRight := make([]bool, len(right))
	var rows []SpanMatch
	var leftOnly []alignedSpan
	for _, leftSpan := range left {
		indexes := rightByKey[leftSpan.keyString]
		if len(indexes) == 0 {
			leftOnly = append(leftOnly, leftSpan)
			continue
		}
		rightIndex := indexes[0]
		rightByKey[leftSpan.keyString] = indexes[1:]
		usedRight[rightIndex] = true
		rightSpan := right[rightIndex]
		diffs := spanDiffs(leftSpan, rightSpan)
		summary.Matched++
		if len(diffs) > 0 {
			summary.Differing++
		}
		rows = append(rows, SpanMatch{
			Kind:      "matched",
			Depth:     depth,
			Left:      spanRef(leftSpan),
			Right:     spanRef(rightSpan),
			LeftCard:  leftSpan.card,
			RightCard: rightSpan.card,
			Diffs:     diffs,
		})
		rows = append(rows, matchSpans(leftSpan.children, rightSpan.children, depth+1, summary)...)
	}
	for _, span := range leftOnly {
		rows = append(rows, onlyRows(span, "left_only", depth, summary)...)
	}
	for i, span := range right {
		if !usedRight[i] {
			rows = append(rows, onlyRows(span, "right_only", depth, summary)...)
		}
	}
	return rows
}

func onlyRows(span alignedSpan, kind string, depth int, summary *AlignSummary) []SpanMatch {
	row := SpanMatch{Kind: kind, Depth: depth}
	if kind == "left_only" {
		row.Left, row.LeftCard = spanRef(span), span.card
		summary.LeftOnly++
	} else {
		row.Right, row.RightCard = spanRef(span), span.card
		summary.RightOnly++
	}
	rows := []SpanMatch{row}
	for _, child := range span.children {
		rows = append(rows, onlyRows(child, kind, depth+1, summary)...)
	}
	return rows
}

type resolvedTrace struct {
	index int
	card  string
	roots []alignedSpan
	key   string
	label string
}

func resolveTraceGroup(index int, group TraceGroup, opposite map[string]int) resolvedTrace {
	if len(group.Alternatives) > 0 {
		best := resolveTraceGroup(index, group.Alternatives[0], opposite)
		bestScore := -1
		for _, alternative := range group.Alternatives {
			candidate := resolveTraceGroup(index, alternative, opposite)
			keys := map[string]int{}
			subtreeKeys(candidate.roots, keys)
			score := 0
			for key, count := range keys {
				if available := opposite[key]; available > 0 {
					if count < available {
						score += count
					} else {
						score += available
					}
				}
			}
			if score > bestScore {
				best, bestScore = candidate, score
			}
		}
		best.card = formatCard(group.MinCount, group.MaxCount, false, len(group.Alternatives))
		return best
	}
	minCount, maxCount := traceBounds(group)
	trace := resolvedTrace{index: index, card: formatCard(minCount, maxCount, group.ExactCount, 0)}
	trace.roots = chooseCandidates(group.Roots, opposite)
	if len(trace.roots) > 0 {
		trace.key = rootKey(trace.roots[0].node)
		trace.label = strings.TrimSpace(trace.roots[0].node.Name)
	}
	return trace
}

func traceCandidateKeys(groups []TraceGroup) map[string]int {
	keys := map[string]int{}
	var visit func(TraceGroup)
	visit = func(group TraceGroup) {
		for _, alternative := range group.Alternatives {
			visit(alternative)
		}
		for key, count := range candidateKeys(group.Roots) {
			keys[key] += count
		}
	}
	for _, group := range groups {
		visit(group)
	}
	return keys
}

// AlignShapes pairs the trace groups of two scenario shapes by root span and
// aligns their spans. It works whether or not the shapes carry exact counts.
func AlignShapes(left, right *ScenarioShape) *ShapeAlignment {
	if left == nil || right == nil {
		return nil
	}
	leftKeys, rightKeys := traceCandidateKeys(left.Traces), traceCandidateKeys(right.Traces)
	leftTraces := make([]resolvedTrace, 0, len(left.Traces))
	for i, group := range left.Traces {
		leftTraces = append(leftTraces, resolveTraceGroup(i, group, rightKeys))
	}
	rightTraces := make([]resolvedTrace, 0, len(right.Traces))
	for i, group := range right.Traces {
		rightTraces = append(rightTraces, resolveTraceGroup(i, group, leftKeys))
	}
	alignment := &ShapeAlignment{Traces: []TraceMatch{}}
	usedRight := make([]bool, len(rightTraces))
	pairRight := func(trace resolvedTrace, exact bool) int {
		for i, candidate := range rightTraces {
			if usedRight[i] {
				continue
			}
			if exact && candidate.key == trace.key {
				return i
			}
			if !exact && spanKeyOnly(candidate.key) == spanKeyOnly(trace.key) {
				return i
			}
		}
		return -1
	}
	for _, leftTrace := range leftTraces {
		index := pairRight(leftTrace, true)
		if index < 0 {
			index = pairRight(leftTrace, false)
		}
		if index < 0 {
			alignment.Traces = append(alignment.Traces, traceOnly(leftTrace, "left_only", &alignment.Summary))
			alignment.Summary.TraceLeftOnly++
			continue
		}
		usedRight[index] = true
		rightTrace := rightTraces[index]
		alignment.Summary.TraceMatched++
		match := TraceMatch{
			Kind:  "matched",
			Left:  &TraceRef{Index: leftTrace.index, Label: leftTrace.label, Card: leftTrace.card},
			Right: &TraceRef{Index: rightTrace.index, Label: rightTrace.label, Card: rightTrace.card},
			Spans: matchSpans(leftTrace.roots, rightTrace.roots, 0, &alignment.Summary),
		}
		alignment.Traces = append(alignment.Traces, match)
	}
	for i, rightTrace := range rightTraces {
		if usedRight[i] {
			continue
		}
		alignment.Traces = append(alignment.Traces, traceOnly(rightTrace, "right_only", &alignment.Summary))
		alignment.Summary.TraceRightOnly++
	}
	return alignment
}

func spanKeyOnly(key string) string {
	if index := strings.LastIndex(key, "\x00"); index >= 0 {
		return key[:index]
	}
	return key
}

func traceOnly(trace resolvedTrace, kind string, summary *AlignSummary) TraceMatch {
	match := TraceMatch{Kind: kind}
	reference := &TraceRef{Index: trace.index, Label: trace.label, Card: trace.card}
	if kind == "left_only" {
		match.Left = reference
	} else {
		match.Right = reference
	}
	for _, root := range trace.roots {
		match.Spans = append(match.Spans, onlyRows(root, kind, 0, summary)...)
	}
	return match
}
