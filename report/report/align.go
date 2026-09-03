package report

import (
	"fmt"
	"regexp"
	"sort"
	"strings"
)

// Alignment pairs the traces and spans of two scenario shapes so a reader can
// see which spans exist on both sides, which differ, and which are unique to a
// single implementation. It renders no verdict: matching is purely structural.

var pathParameterPattern = regexp.MustCompile(`%?\{[^}]*\}|<[^>]*>`)
var colonPathParameterPattern = regexp.MustCompile(`(^|/):[A-Za-z_][A-Za-z0-9_]*`)
var whitespacePattern = regexp.MustCompile(`\s+`)

// NormalizeSpanName lowercases a span name, drops a leading slash on the route
// portion, and rewrites path parameters to "*" so routes that differ only in
// the parameter syntax used by a framework still align.
func NormalizeSpanName(name string) string {
	normalized := strings.ToLower(strings.TrimSpace(name))
	normalized = pathParameterPattern.ReplaceAllString(normalized, "*")
	normalized = colonPathParameterPattern.ReplaceAllString(normalized, "${1}*")
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

func spanMatchScore(left, right SpanNode) int {
	score := 0
	if left.Kind != "" && right.Kind != "" {
		if left.Kind != right.Kind {
			return -1
		}
		score += 10
	} else if left.Kind != "" || right.Kind != "" {
		score++
	}
	leftName, rightName := NormalizeSpanName(left.Name), NormalizeSpanName(right.Name)
	if leftName != "" && rightName != "" {
		if leftName != rightName {
			return -1
		}
		score += 100
	} else if leftName != "" || rightName != "" {
		score++
	}
	return score
}

// alignedSpanMatchScore keeps name and kind as the compatibility boundary,
// then uses rendered details to pair otherwise-identical sibling spans.
func alignedSpanMatchScore(left, right alignedSpan) int {
	score := spanMatchScore(left.node, right.node)
	if score < 0 {
		return score
	}
	if left.node.Status != "" && left.node.Status == right.node.Status {
		score += 8
	}
	if left.node.HTTPStatus != "" && left.node.HTTPStatus == right.node.HTTPStatus {
		score += 4
	}
	if left.card == right.card {
		score += 2
	}
	return score
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

func canonicalSpanKey(span alignedSpan) string {
	children := make([]string, 0, len(span.children))
	for _, child := range span.children {
		children = append(children, canonicalSpanKey(child))
	}
	sort.Strings(children)
	return strings.Join([]string{span.keyString, span.node.Status, span.node.HTTPStatus, span.card, strings.Join(children, "\x1e")}, "\x1f")
}

// chooseCandidates jointly picks candidates for sibling groups. Each choice
// consumes matching opposite-side keys, so two independent one-of groups do
// not both claim the same counterpart.
func chooseCandidates(groups []SpanGroup, opposite map[string]int) []alignedSpan {
	choices := make([][]alignedSpan, 0, len(groups))
	for _, group := range groups {
		candidates := resolveSpanGroup(group, opposite)
		if len(candidates) == 0 {
			continue
		}
		choices = append(choices, candidates)
	}
	if len(choices) == 0 {
		return nil
	}
	available := make(map[string]int, len(opposite))
	for key, count := range opposite {
		available[key] = count
	}
	bestScore, bestKey := -1, ""
	var best []alignedSpan
	var search func(index, score int, key string, picked []alignedSpan)
	search = func(index, score int, key string, picked []alignedSpan) {
		if index == len(choices) {
			if score > bestScore || (score == bestScore && key < bestKey) {
				bestScore, bestKey = score, key
				best = append([]alignedSpan(nil), picked...)
			}
			return
		}
		for _, candidate := range choices[index] {
			keys := map[string]int{}
			subtreeKeys([]alignedSpan{candidate}, keys)
			delta := 0
			for candidateKey, count := range keys {
				if count < available[candidateKey] {
					delta += count
				} else {
					delta += available[candidateKey]
				}
			}
			if candidate.keyString != "" && available[candidate.keyString] > 0 {
				delta += 100
			}
			for candidateKey, count := range keys {
				if count < available[candidateKey] {
					available[candidateKey] -= count
				} else {
					available[candidateKey] = 0
				}
			}
			candidateKey := canonicalSpanKey(candidate)
			search(index+1, score+delta, key+"\x1d"+candidateKey, append(picked, candidate))
			for key, count := range keys {
				available[key] += count
				if available[key] > opposite[key] {
					available[key] = opposite[key]
				}
			}
		}
	}
	search(0, 0, "", nil)
	return best
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

// maximumMatchingSize returns the number of compatible pairs still available
// after start. It is the cardinality constraint used before detail scores are
// allowed to break ties.
func maximumMatchingSize(left, right []alignedSpan, start int, usedRight []bool, score func(alignedSpan, alignedSpan) int) int {
	matchedRight := make([]int, len(right))
	for i := range matchedRight {
		matchedRight[i] = -1
		if usedRight != nil && usedRight[i] {
			matchedRight[i] = -2
		}
	}
	var assign func(int, []bool) bool
	assign = func(leftIndex int, seen []bool) bool {
		for rightIndex := range right {
			if seen[rightIndex] || matchedRight[rightIndex] == -2 || score(left[leftIndex], right[rightIndex]) < 0 {
				continue
			}
			seen[rightIndex] = true
			if matchedRight[rightIndex] < 0 || assign(matchedRight[rightIndex], seen) {
				matchedRight[rightIndex] = leftIndex
				return true
			}
		}
		return false
	}
	matched := 0
	for leftIndex := start; leftIndex < len(left); leftIndex++ {
		if assign(leftIndex, make([]bool, len(right))) {
			matched++
		}
	}
	return matched
}

// maximumCardinalityPairs first preserves every compatible pair possible, then
// uses the supplied score only to choose among pairings with that cardinality.
func maximumCardinalityPairs(left, right []alignedSpan, score func(alignedSpan, alignedSpan) int) ([]int, []bool) {
	target := maximumMatchingSize(left, right, 0, nil, score)
	matchedRight := make([]int, len(left))
	for i := range matchedRight {
		matchedRight[i] = -1
	}
	usedRight := make([]bool, len(right))
	matched := 0
	for leftIndex := range left {
		type candidate struct{ right, score int }
		var candidates []candidate
		for rightIndex := range right {
			if usedRight[rightIndex] {
				continue
			}
			if candidateScore := score(left[leftIndex], right[rightIndex]); candidateScore >= 0 {
				candidates = append(candidates, candidate{right: rightIndex, score: candidateScore})
			}
		}
		sort.SliceStable(candidates, func(i, j int) bool {
			return candidates[i].score > candidates[j].score
		})
		for _, candidate := range candidates {
			usedRight[candidate.right] = true
			remaining := maximumMatchingSize(left, right, leftIndex+1, usedRight, score)
			if matched+1+remaining >= target {
				matchedRight[leftIndex] = candidate.right
				matched++
				break
			}
			usedRight[candidate.right] = false
		}
	}
	return matchedRight, usedRight
}

// matchSpans pairs two sibling lists and emits depth-annotated rows in a
// stable order: matched pairs first (in left order), then spans that exist only
// on the left, then spans only on the right.
func matchSpans(left, right []alignedSpan, depth int, summary *AlignSummary) []SpanMatch {
	matchedRight, usedRight := maximumCardinalityPairs(left, right, alignedSpanMatchScore)
	var rows []SpanMatch
	var leftOnly []alignedSpan
	for leftIndex, leftSpan := range left {
		rightIndex := matchedRight[leftIndex]
		if rightIndex < 0 {
			leftOnly = append(leftOnly, leftSpan)
			continue
		}
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
	label string
}

func canonicalTraceKey(trace resolvedTrace) string {
	roots := make([]string, 0, len(trace.roots))
	for _, root := range trace.roots {
		roots = append(roots, canonicalSpanKey(root))
	}
	sort.Strings(roots)
	return strings.Join([]string{trace.card, strings.Join(roots, "\x1e")}, "\x1f")
}

func resolveTraceGroup(index int, group TraceGroup, opposite map[string]int) resolvedTrace {
	if len(group.Alternatives) > 0 {
		best := resolveTraceGroup(index, group.Alternatives[0], opposite)
		bestScore, bestKey := -1, ""
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
			candidateKey := canonicalTraceKey(candidate)
			if score > bestScore || (score == bestScore && candidateKey < bestKey) {
				best, bestScore, bestKey = candidate, score, candidateKey
			}
		}
		best.card = formatCard(group.MinCount, group.MaxCount, false, len(group.Alternatives))
		return best
	}
	minCount, maxCount := traceBounds(group)
	trace := resolvedTrace{index: index, card: formatCard(minCount, maxCount, group.ExactCount, 0)}
	trace.roots = chooseCandidates(group.Roots, opposite)
	if len(trace.roots) > 0 {
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

// traceMatchScore treats roots as an unordered set. It rewards each compatible
// root pairing, then uses the same detail-aware score as sibling alignment so
// equivalent multi-root traces remain stable when authored in a different
// order.
func traceMatchScore(left, right resolvedTrace) int {
	type candidate struct{ left, right, score int }
	var candidates []candidate
	for leftIndex, leftRoot := range left.roots {
		for rightIndex, rightRoot := range right.roots {
			score := alignedSpanMatchScore(leftRoot, rightRoot)
			if score < 0 {
				continue
			}
			leftHTTP, rightHTTP := leftRoot.node.HTTPStatus, rightRoot.node.HTTPStatus
			if leftHTTP == "" || rightHTTP == "" || leftHTTP == rightHTTP {
				score += 1000
			}
			if leftHTTP != "" && leftHTTP == rightHTTP {
				score += 10
			}
			candidates = append(candidates, candidate{left: leftIndex, right: rightIndex, score: score})
		}
	}
	sort.SliceStable(candidates, func(i, j int) bool { return candidates[i].score > candidates[j].score })
	usedLeft, usedRight := make([]bool, len(left.roots)), make([]bool, len(right.roots))
	matched, total := 0, 0
	for _, candidate := range candidates {
		if usedLeft[candidate.left] || usedRight[candidate.right] {
			continue
		}
		usedLeft[candidate.left], usedRight[candidate.right] = true, true
		matched++
		total += candidate.score
	}
	if matched == 0 {
		return -1
	}
	return matched*100000 + total
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
	type candidate struct{ left, right, score int }
	var candidates []candidate
	for leftIndex, leftTrace := range leftTraces {
		if len(leftTrace.roots) == 0 {
			continue
		}
		for rightIndex, rightTrace := range rightTraces {
			if len(rightTrace.roots) == 0 {
				continue
			}
			score := traceMatchScore(leftTrace, rightTrace)
			if score < 0 {
				continue
			}
			candidates = append(candidates, candidate{left: leftIndex, right: rightIndex, score: score})
		}
	}
	sort.SliceStable(candidates, func(i, j int) bool { return candidates[i].score > candidates[j].score })
	matchedRight := make([]int, len(leftTraces))
	for i := range matchedRight {
		matchedRight[i] = -1
	}
	usedRight := make([]bool, len(rightTraces))
	for _, candidate := range candidates {
		if matchedRight[candidate.left] >= 0 || usedRight[candidate.right] {
			continue
		}
		matchedRight[candidate.left] = candidate.right
		usedRight[candidate.right] = true
	}
	for leftIndex, leftTrace := range leftTraces {
		index := matchedRight[leftIndex]
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
