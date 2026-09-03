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
func resolveSpanGroup(group SpanGroup, opposite, oppositeDetails map[string]int) []alignedSpan {
	if len(group.Alternatives) > 0 {
		var candidates []alignedSpan
		for _, alternative := range group.Alternatives {
			for _, candidate := range resolveSpanGroup(alternative, opposite, oppositeDetails) {
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
	span.children = chooseCandidates(group.Span.Children, opposite, oppositeDetails)
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

// subtreeDetailKeys includes the rendered fields that distinguish otherwise
// structurally-identical alternatives, such as a status or HTTP response.
func subtreeDetailKeys(spans []alignedSpan, into map[string]int) {
	for _, span := range spans {
		key := strings.Join([]string{span.keyString, span.node.Status, span.node.HTTPStatus, fmt.Sprintf("%d:%d:%t", span.minCount, span.maxCount, span.exact)}, "\x1f")
		into[key]++
		subtreeDetailKeys(span.children, into)
	}
}

func spanNodeFromKey(key string) SpanNode {
	parts := strings.SplitN(key, "\x00", 2)
	node := SpanNode{Kind: parts[0]}
	if len(parts) == 2 {
		node.Name = parts[1]
	}
	return node
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

// chooseCandidates jointly picks candidates for sibling groups. Each choice
// consumes matching opposite-side keys, so two independent one-of groups do
// not both claim the same counterpart.
func chooseCandidates(groups []SpanGroup, opposite, oppositeDetails map[string]int) []alignedSpan {
	choices := make([][]alignedSpan, 0, len(groups))
	for _, group := range groups {
		candidates := resolveSpanGroup(group, opposite, oppositeDetails)
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
	detailAvailable := make(map[string]int, len(oppositeDetails))
	for key, count := range oppositeDetails {
		detailAvailable[key] = count
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
			details := map[string]int{}
			subtreeDetailKeys([]alignedSpan{candidate}, details)
			delta := 0
			consumed := map[string]int{}
			for candidateKey, count := range keys {
				taken := min(count, available[candidateKey])
				consumed[candidateKey] = taken
				delta += taken
				for remaining := count - taken; remaining > 0; {
					bestKey, bestScore := "", -1
					for oppositeKey, availableCount := range available {
						if availableCount-consumed[oppositeKey] <= 0 {
							continue
						}
						if score := spanMatchScore(spanNodeFromKey(candidateKey), spanNodeFromKey(oppositeKey)); score > bestScore {
							bestKey, bestScore = oppositeKey, score
						}
					}
					if bestScore < 0 {
						break
					}
					consumed[bestKey]++
					delta++
					remaining--
				}
			}
			if candidate.keyString != "" && available[candidate.keyString] > 0 {
				delta += 100
			}
			for detailKey, count := range details {
				if count < detailAvailable[detailKey] {
					delta += count * 10
				} else {
					delta += detailAvailable[detailKey] * 10
				}
			}
			for candidateKey := range keys {
				available[candidateKey] -= consumed[candidateKey]
			}
			for candidateKey, count := range consumed {
				if _, direct := keys[candidateKey]; !direct {
					available[candidateKey] -= count
				}
			}
			detailConsumed := map[string]int{}
			for detailKey, count := range details {
				detailConsumed[detailKey] = min(count, detailAvailable[detailKey])
				detailAvailable[detailKey] -= detailConsumed[detailKey]
			}
			candidateKey := canonicalSpanKey(candidate)
			search(index+1, score+delta, key+"\x1d"+candidateKey, append(picked, candidate))
			for key, count := range consumed {
				available[key] += count
			}
			for detailKey, count := range detailConsumed {
				detailAvailable[detailKey] += count
			}
		}
	}
	search(0, 0, "", nil)
	return best
}

func candidateKeys(groups []SpanGroup) map[string]int {
	keys := map[string]int{}
	for _, group := range groups {
		for _, candidate := range resolveSpanGroup(group, nil, nil) {
			subtreeKeys([]alignedSpan{candidate}, keys)
		}
	}
	return keys
}

func candidateDetailKeys(groups []SpanGroup) map[string]int {
	keys := map[string]int{}
	for _, group := range groups {
		for _, candidate := range resolveSpanGroup(group, nil, nil) {
			subtreeDetailKeys([]alignedSpan{candidate}, keys)
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

func traceGroupCandidates(index int, group TraceGroup, opposite, oppositeDetails map[string]int) []resolvedTrace {
	if len(group.Alternatives) > 0 {
		var candidates []resolvedTrace
		for _, alternative := range group.Alternatives {
			for _, candidate := range traceGroupCandidates(index, alternative, opposite, oppositeDetails) {
				candidate.card = formatCard(group.MinCount, group.MaxCount, false, len(group.Alternatives))
				candidates = append(candidates, candidate)
			}
		}
		return candidates
	}
	minCount, maxCount := traceBounds(group)
	trace := resolvedTrace{index: index, card: formatCard(minCount, maxCount, group.ExactCount, 0)}
	trace.roots = chooseCandidates(group.Roots, opposite, oppositeDetails)
	if len(trace.roots) > 0 {
		trace.label = strings.TrimSpace(trace.roots[0].node.Name)
	}
	return []resolvedTrace{trace}
}

// chooseTraceCandidates jointly resolves trace-level alternatives, preventing
// one trace group from selecting a counterpart needed by a later group.
func chooseTraceCandidates(groups []TraceGroup, opposite, oppositeDetails map[string]int) []resolvedTrace {
	choices := make([][]resolvedTrace, 0, len(groups))
	for index, group := range groups {
		choices = append(choices, traceGroupCandidates(index, group, opposite, oppositeDetails))
	}
	available, detailAvailable := map[string]int{}, map[string]int{}
	for key, count := range opposite {
		available[key] = count
	}
	for key, count := range oppositeDetails {
		detailAvailable[key] = count
	}
	bestScore, bestKey := -1, ""
	var best []resolvedTrace
	var search func(int, int, string, []resolvedTrace)
	search = func(index, score int, key string, picked []resolvedTrace) {
		if index == len(choices) {
			if score > bestScore || (score == bestScore && key < bestKey) {
				bestScore, bestKey, best = score, key, append([]resolvedTrace(nil), picked...)
			}
			return
		}
		for _, candidate := range choices[index] {
			keys, details := map[string]int{}, map[string]int{}
			subtreeKeys(candidate.roots, keys)
			subtreeDetailKeys(candidate.roots, details)
			delta, consumed := 0, map[string]int{}
			for item, count := range keys {
				taken := min(count, available[item])
				consumed[item] = taken
				delta += taken
				for remaining := count - taken; remaining > 0; remaining-- {
					bestKey, bestScore := "", -1
					for oppositeKey, availableCount := range available {
						if availableCount-consumed[oppositeKey] <= 0 {
							continue
						}
						if score := spanMatchScore(spanNodeFromKey(item), spanNodeFromKey(oppositeKey)); score > bestScore {
							bestKey, bestScore = oppositeKey, score
						}
					}
					if bestScore < 0 {
						break
					}
					consumed[bestKey]++
					delta++
				}
			}
			for item, count := range details {
				delta += min(count, detailAvailable[item]) * 10
			}
			for item, count := range consumed {
				available[item] -= count
			}
			detailConsumed := map[string]int{}
			for item, count := range details {
				detailConsumed[item] = min(count, detailAvailable[item])
				detailAvailable[item] -= detailConsumed[item]
			}
			search(index+1, score+delta, key+"\x1d"+canonicalTraceKey(candidate), append(picked, candidate))
			for item, count := range consumed {
				available[item] += count
			}
			for item, count := range detailConsumed {
				detailAvailable[item] += count
			}
		}
	}
	search(0, 0, "", nil)
	return best
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

func traceCandidateDetailKeys(groups []TraceGroup) map[string]int {
	keys := map[string]int{}
	var visit func(TraceGroup)
	visit = func(group TraceGroup) {
		for _, alternative := range group.Alternatives {
			visit(alternative)
		}
		for key, count := range candidateDetailKeys(group.Roots) {
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
	return matched*100000 + total
}

func maximumTraceMatchingSize(left, right []resolvedTrace, start int, usedRight []bool) int {
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
			if seen[rightIndex] || matchedRight[rightIndex] == -2 || traceMatchScore(left[leftIndex], right[rightIndex]) < 0 {
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

func maximumCardinalityTracePairs(left, right []resolvedTrace) ([]int, []bool) {
	target := maximumTraceMatchingSize(left, right, 0, nil)
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
			if score := traceMatchScore(left[leftIndex], right[rightIndex]); score >= 0 {
				candidates = append(candidates, candidate{right: rightIndex, score: score})
			}
		}
		sort.SliceStable(candidates, func(i, j int) bool { return candidates[i].score > candidates[j].score })
		for _, candidate := range candidates {
			usedRight[candidate.right] = true
			remaining := maximumTraceMatchingSize(left, right, leftIndex+1, usedRight)
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

// AlignShapes pairs the trace groups of two scenario shapes by root span and
// aligns their spans. It works whether or not the shapes carry exact counts.
func AlignShapes(left, right *ScenarioShape) *ShapeAlignment {
	if left == nil || right == nil {
		return nil
	}
	leftKeys, rightKeys := traceCandidateKeys(left.Traces), traceCandidateKeys(right.Traces)
	leftDetails, rightDetails := traceCandidateDetailKeys(left.Traces), traceCandidateDetailKeys(right.Traces)
	leftTraces := chooseTraceCandidates(left.Traces, rightKeys, rightDetails)
	rightTraces := chooseTraceCandidates(right.Traces, leftKeys, leftDetails)
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
