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

func isHTTPMethod(value string) bool {
	switch value {
	case "connect", "delete", "get", "head", "options", "patch", "post", "put", "trace":
		return true
	default:
		return false
	}
}

// NormalizeSpanName lowercases a span name, drops a leading slash on the route
// portion, and rewrites path parameters to "*" so routes that differ only in
// the parameter syntax used by a framework still align.
func NormalizeSpanName(name string) string {
	normalized := strings.ToLower(strings.TrimSpace(name))
	normalized = whitespacePattern.ReplaceAllString(normalized, " ")
	fields := strings.Split(normalized, " ")
	for i, field := range fields {
		// Some instrumentations omit the route's leading slash. Recognize that
		// form only after an HTTP method so SQL/JSON placeholders are preserved.
		isRoute := strings.HasPrefix(field, "/") ||
			(i > 0 && isHTTPMethod(fields[i-1]) && strings.Contains(field, "/"))
		if isRoute && len(field) > 1 {
			field = pathParameterPattern.ReplaceAllString(field, "*")
			field = colonPathParameterPattern.ReplaceAllString(field, "${1}*")
			fields[i] = strings.TrimPrefix(field, "/")
		}
	}
	return strings.Join(fields, " ")
}

type alignedSpan struct {
	node        SpanNode
	card        string
	minCount    int
	maxCount    int
	exact       bool
	altCount    int
	children    []alignedSpan
	childGroups []SpanGroup
	keyString   string
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
	} else if left.Kind == "" && right.Kind == "" {
		// Prefer two equally-unspecified matchers over consuming a concrete
		// sibling with a wildcard.
		score += 2
	}
	leftName, rightName := NormalizeSpanName(left.Name), NormalizeSpanName(right.Name)
	if leftName != "" && rightName != "" {
		if leftName != rightName {
			return -1
		}
		score += 100
	} else if leftName == "" && rightName == "" {
		// Prefer two equally-unspecified matchers over consuming a concrete
		// sibling with a wildcard.
		score += 2
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
	if left.childGroups != nil || right.childGroups != nil {
		left.children, right.children = choosePairedCandidates(left.childGroups, right.childGroups)
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
	if canonicalChildrenKey(left) == canonicalChildrenKey(right) {
		// Sibling order is not meaningful. When otherwise-identical parents
		// have different descendants, prefer the pairing that keeps their
		// equivalent subtrees together.
		score += 1
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
func resolveSpanGroup(group SpanGroup) []alignedSpan {
	if len(group.Alternatives) > 0 {
		var candidates []alignedSpan
		for _, alternative := range group.Alternatives {
			for _, candidate := range resolveSpanGroup(alternative) {
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
	span.childGroups = group.Span.Children
	span.children = canonicalSpanCandidates(group.Span.Children)
	return []alignedSpan{span}
}

func canonicalSpanKey(span alignedSpan) string {
	return strings.Join([]string{span.keyString, span.node.Status, span.node.HTTPStatus, span.card, canonicalChildrenKey(span)}, "\x1f")
}

func canonicalChildrenKey(span alignedSpan) string {
	children := make([]string, 0, len(span.children))
	for _, child := range span.children {
		children = append(children, canonicalSpanKey(child))
	}
	sort.Strings(children)
	return strings.Join(children, "\x1e")
}

func spanCandidateLists(groups []SpanGroup) [][]alignedSpan {
	lists := [][]alignedSpan{{}}
	for _, group := range groups {
		candidates := resolveSpanGroup(group)
		if len(candidates) == 0 {
			continue
		}
		next := make([][]alignedSpan, 0, len(lists)*len(candidates))
		for _, list := range lists {
			for _, candidate := range candidates {
				picked := append([]alignedSpan(nil), list...)
				next = append(next, append(picked, candidate))
			}
		}
		lists = next
	}
	return lists
}

func canonicalSpanListKey(spans []alignedSpan) string {
	keys := make([]string, 0, len(spans))
	for _, span := range spans {
		keys = append(keys, canonicalSpanKey(span))
	}
	sort.Strings(keys)
	return strings.Join(keys, "\x1d")
}

func canonicalSpanCandidates(groups []SpanGroup) []alignedSpan {
	lists := spanCandidateLists(groups)
	best := lists[0]
	bestKey := canonicalSpanListKey(best)
	for _, candidate := range lists[1:] {
		if key := canonicalSpanListKey(candidate); key < bestKey {
			best, bestKey = candidate, key
		}
	}
	return append([]alignedSpan(nil), best...)
}

func pairedSpanListScore(left, right []alignedSpan) (int, int) {
	matchedRight, _ := maximumCardinalityPairs(left, right, alignedSpanMatchScore)
	matched, detail := 0, 0
	for leftIndex, rightIndex := range matchedRight {
		if rightIndex < 0 {
			continue
		}
		matched++
		detail += alignedSpanMatchScore(left[leftIndex], right[rightIndex])
	}
	return matched, detail
}

// choosePairedCandidates evaluates the alternatives from both sibling lists
// together. This avoids each side selecting a candidate that exists only in
// the other side's discarded alternatives, and lets the assignment optimizer
// decide which concrete node a wildcard should consume.
func choosePairedCandidates(leftGroups, rightGroups []SpanGroup) ([]alignedSpan, []alignedSpan) {
	leftLists, rightLists := spanCandidateLists(leftGroups), spanCandidateLists(rightGroups)
	bestMatched, bestDetail, bestKey := -1, -1, ""
	var bestLeft, bestRight []alignedSpan
	for _, left := range leftLists {
		for _, right := range rightLists {
			matched, detail := pairedSpanListScore(left, right)
			key := canonicalSpanListKey(left) + "\x1c" + canonicalSpanListKey(right)
			if matched > bestMatched ||
				(matched == bestMatched && detail > bestDetail) ||
				(matched == bestMatched && detail == bestDetail && (bestKey == "" || key < bestKey)) {
				bestMatched, bestDetail, bestKey = matched, detail, key
				bestLeft = append([]alignedSpan(nil), left...)
				bestRight = append([]alignedSpan(nil), right...)
			}
		}
	}
	return bestLeft, bestRight
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

// maximumWeightAssignment returns the maximum-weight perfect assignment for a
// square matrix. It is the Hungarian algorithm expressed as a minimum-cost
// assignment over negated weights.
func maximumWeightAssignment(weights [][]int) []int {
	size := len(weights)
	leftPotential, rightPotential := make([]int, size+1), make([]int, size+1)
	matchedColumn, previous := make([]int, size+1), make([]int, size+1)
	const infinity = int(^uint(0)>>1) / 4
	for row := 1; row <= size; row++ {
		matchedColumn[0] = row
		column := 0
		minCost := make([]int, size+1)
		used := make([]bool, size+1)
		for index := 1; index <= size; index++ {
			minCost[index] = infinity
		}
		for {
			used[column] = true
			matchedRow := matchedColumn[column]
			delta, nextColumn := infinity, 0
			for candidate := 1; candidate <= size; candidate++ {
				if used[candidate] {
					continue
				}
				cost := -weights[matchedRow-1][candidate-1] - leftPotential[matchedRow] - rightPotential[candidate]
				if cost < minCost[candidate] {
					minCost[candidate], previous[candidate] = cost, column
				}
				if minCost[candidate] < delta {
					delta, nextColumn = minCost[candidate], candidate
				}
			}
			for candidate := 0; candidate <= size; candidate++ {
				if used[candidate] {
					leftPotential[matchedColumn[candidate]] += delta
					rightPotential[candidate] -= delta
				} else {
					minCost[candidate] -= delta
				}
			}
			column = nextColumn
			if matchedColumn[column] == 0 {
				break
			}
		}
		for {
			previousColumn := previous[column]
			matchedColumn[column] = matchedColumn[previousColumn]
			column = previousColumn
			if column == 0 {
				break
			}
		}
	}
	assignment := make([]int, size)
	for column := 1; column <= size; column++ {
		assignment[matchedColumn[column]-1] = column - 1
	}
	return assignment
}

// maximumWeightMaximumCardinalityPairs gives every compatible edge a bonus
// larger than all possible detail scores, then maximizes the total weight.
// The result therefore preserves the greatest number of matches while making
// the globally best detail-aware pairing among those matchings.
func maximumWeightMaximumCardinalityPairs(leftCount, rightCount int, score func(int, int) int) ([]int, []bool) {
	matchedRight := make([]int, leftCount)
	for index := range matchedRight {
		matchedRight[index] = -1
	}
	usedRight := make([]bool, rightCount)
	if leftCount == 0 || rightCount == 0 {
		return matchedRight, usedRight
	}
	scores, highest := make([][]int, leftCount), 0
	for leftIndex := 0; leftIndex < leftCount; leftIndex++ {
		scores[leftIndex] = make([]int, rightCount)
		for rightIndex := 0; rightIndex < rightCount; rightIndex++ {
			scores[leftIndex][rightIndex] = score(leftIndex, rightIndex)
			if scores[leftIndex][rightIndex] > highest {
				highest = scores[leftIndex][rightIndex]
			}
		}
	}
	bonus := (highest + 1) * (min(leftCount, rightCount) + 1)
	size := leftCount + rightCount
	weights := make([][]int, size)
	for index := range weights {
		weights[index] = make([]int, size)
	}
	for leftIndex := 0; leftIndex < leftCount; leftIndex++ {
		for rightIndex := 0; rightIndex < rightCount; rightIndex++ {
			if scores[leftIndex][rightIndex] >= 0 {
				weights[leftIndex][rightIndex] = bonus + scores[leftIndex][rightIndex]
			}
		}
	}
	assignment := maximumWeightAssignment(weights)
	for leftIndex := 0; leftIndex < leftCount; leftIndex++ {
		rightIndex := assignment[leftIndex]
		if rightIndex < rightCount && scores[leftIndex][rightIndex] >= 0 {
			matchedRight[leftIndex], usedRight[rightIndex] = rightIndex, true
		}
	}
	return matchedRight, usedRight
}

func maximumCardinalityPairs(left, right []alignedSpan, score func(alignedSpan, alignedSpan) int) ([]int, []bool) {
	return maximumWeightMaximumCardinalityPairs(len(left), len(right), func(leftIndex, rightIndex int) int {
		return score(left[leftIndex], right[rightIndex])
	})
}

func resolvePairedChildren(left, right alignedSpan) ([]alignedSpan, []alignedSpan) {
	if left.childGroups == nil && right.childGroups == nil {
		return left.children, right.children
	}
	return choosePairedCandidates(left.childGroups, right.childGroups)
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
		leftChildren, rightChildren := resolvePairedChildren(leftSpan, rightSpan)
		rows = append(rows, matchSpans(leftChildren, rightChildren, depth+1, summary)...)
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
	index      int
	card       string
	minCount   int
	maxCount   int
	exact      bool
	altCount   int
	coverage   string
	roots      []alignedSpan
	rootGroups []SpanGroup
	label      string
}

func canonicalTraceKey(trace resolvedTrace) string {
	roots := make([]string, 0, len(trace.roots))
	for _, root := range trace.roots {
		roots = append(roots, canonicalSpanKey(root))
	}
	sort.Strings(roots)
	return strings.Join([]string{trace.card, trace.coverage, strings.Join(roots, "\x1e")}, "\x1f")
}

func traceGroupCandidates(index int, group TraceGroup) []resolvedTrace {
	if len(group.Alternatives) > 0 {
		var candidates []resolvedTrace
		for _, alternative := range group.Alternatives {
			for _, candidate := range traceGroupCandidates(index, alternative) {
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
	minCount, maxCount := traceBounds(group)
	trace := resolvedTrace{index: index, minCount: minCount, maxCount: maxCount, exact: group.ExactCount, coverage: group.Coverage}
	trace.card = formatCard(trace.minCount, trace.maxCount, trace.exact, trace.altCount)
	trace.rootGroups = group.Roots
	trace.roots = canonicalSpanCandidates(group.Roots)
	if len(trace.roots) > 0 {
		trace.label = strings.TrimSpace(trace.roots[0].node.Name)
	}
	return []resolvedTrace{trace}
}

func traceCandidateLists(groups []TraceGroup) [][]resolvedTrace {
	lists := [][]resolvedTrace{{}}
	for index, group := range groups {
		candidates := traceGroupCandidates(index, group)
		if len(candidates) == 0 {
			continue
		}
		next := make([][]resolvedTrace, 0, len(lists)*len(candidates))
		for _, list := range lists {
			for _, candidate := range candidates {
				picked := append([]resolvedTrace(nil), list...)
				next = append(next, append(picked, candidate))
			}
		}
		lists = next
	}
	return lists
}

func canonicalTraceListKey(traces []resolvedTrace) string {
	keys := make([]string, 0, len(traces))
	for _, trace := range traces {
		keys = append(keys, canonicalTraceKey(trace))
	}
	sort.Strings(keys)
	return strings.Join(keys, "\x1d")
}

func pairedTraceListScore(left, right []resolvedTrace) (int, int) {
	matchedRight, _ := maximumCardinalityTracePairs(left, right)
	matched, detail := 0, 0
	for leftIndex, rightIndex := range matchedRight {
		if rightIndex < 0 {
			continue
		}
		matched++
		detail += traceMatchScore(left[leftIndex], right[rightIndex])
	}
	return matched, detail
}

func choosePairedTraceCandidates(leftGroups, rightGroups []TraceGroup) ([]resolvedTrace, []resolvedTrace) {
	leftLists, rightLists := traceCandidateLists(leftGroups), traceCandidateLists(rightGroups)
	bestMatched, bestDetail, bestKey := -1, -1, ""
	var bestLeft, bestRight []resolvedTrace
	for _, left := range leftLists {
		for _, right := range rightLists {
			matched, detail := pairedTraceListScore(left, right)
			key := canonicalTraceListKey(left) + "\x1c" + canonicalTraceListKey(right)
			if matched > bestMatched ||
				(matched == bestMatched && detail > bestDetail) ||
				(matched == bestMatched && detail == bestDetail && (bestKey == "" || key < bestKey)) {
				bestMatched, bestDetail, bestKey = matched, detail, key
				bestLeft = append([]resolvedTrace(nil), left...)
				bestRight = append([]resolvedTrace(nil), right...)
			}
		}
	}
	return bestLeft, bestRight
}

// traceMatchScore treats roots as an unordered set. It rewards each compatible
// root pairing, then uses the same detail-aware score as sibling alignment so
// equivalent multi-root traces remain stable when authored in a different
// order.
func traceMatchScore(left, right resolvedTrace) int {
	if left.rootGroups != nil || right.rootGroups != nil {
		left.roots, right.roots = choosePairedCandidates(left.rootGroups, right.rootGroups)
	}
	rootScore := func(leftRoot, rightRoot alignedSpan) int {
		score := alignedSpanMatchScore(leftRoot, rightRoot)
		if score < 0 {
			return score
		}
		leftHTTP, rightHTTP := leftRoot.node.HTTPStatus, rightRoot.node.HTTPStatus
		if leftHTTP == "" || rightHTTP == "" || leftHTTP == rightHTTP {
			score += 1000
		}
		if leftHTTP != "" && leftHTTP == rightHTTP {
			score += 10
		}
		return score
	}
	matchedRight, _ := maximumCardinalityPairs(left.roots, right.roots, rootScore)
	matched, total := 0, 0
	for leftIndex, rightIndex := range matchedRight {
		if rightIndex < 0 {
			continue
		}
		matched++
		total += rootScore(left.roots[leftIndex], right.roots[rightIndex])
	}
	if matched == 0 {
		return -1
	}
	// Root compatibility decides the pair first. Card and coverage then keep
	// otherwise-identical root sets paired with their semantically equivalent
	// trace group rather than relying on authored order.
	if left.card == right.card {
		total += 100
	}
	if left.coverage == right.coverage {
		total += 10
	}
	return matched*100000 + total - (len(left.roots)+len(right.roots)-2*matched)*10000
}

func maximumCardinalityTracePairs(left, right []resolvedTrace) ([]int, []bool) {
	return maximumWeightMaximumCardinalityPairs(len(left), len(right), func(leftIndex, rightIndex int) int {
		return traceMatchScore(left[leftIndex], right[rightIndex])
	})
}

// AlignShapes pairs the trace groups of two scenario shapes by root span and
// aligns their spans. It works whether or not the shapes carry exact counts.
func AlignShapes(left, right *ScenarioShape) *ShapeAlignment {
	if left == nil || right == nil {
		return nil
	}
	leftTraces, rightTraces := choosePairedTraceCandidates(left.Traces, right.Traces)
	alignment := &ShapeAlignment{Traces: []TraceMatch{}}
	matchedRight, usedRight := maximumCardinalityTracePairs(leftTraces, rightTraces)
	for leftIndex, leftTrace := range leftTraces {
		index := matchedRight[leftIndex]
		if index < 0 {
			alignment.Traces = append(alignment.Traces, traceOnly(leftTrace, "left_only", &alignment.Summary))
			alignment.Summary.TraceLeftOnly++
			continue
		}
		usedRight[index] = true
		rightTrace := rightTraces[index]
		leftTrace.roots, rightTrace.roots = choosePairedCandidates(leftTrace.rootGroups, rightTrace.rootGroups)
		if len(leftTrace.roots) > 0 {
			leftTrace.label = strings.TrimSpace(leftTrace.roots[0].node.Name)
		}
		if len(rightTrace.roots) > 0 {
			rightTrace.label = strings.TrimSpace(rightTrace.roots[0].node.Name)
		}
		alignment.Summary.TraceMatched++
		match := TraceMatch{
			Kind:  "matched",
			Left:  &TraceRef{Index: leftTrace.index, Label: leftTrace.label, Card: leftTrace.card, Coverage: leftTrace.coverage},
			Right: &TraceRef{Index: rightTrace.index, Label: rightTrace.label, Card: rightTrace.card, Coverage: rightTrace.coverage},
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
	reference := &TraceRef{Index: trace.index, Label: trace.label, Card: trace.card, Coverage: trace.coverage}
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
