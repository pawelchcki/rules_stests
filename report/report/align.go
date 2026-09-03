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
	span.childGroups = group.Span.Children
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

type spanDetail struct {
	node   SpanNode
	status string
	http   string
	count  string
}

func parseSpanDetail(key string) spanDetail {
	parts := strings.SplitN(key, "\x1f", 4)
	detail := spanDetail{node: spanNodeFromKey(parts[0])}
	if len(parts) > 1 {
		detail.status = parts[1]
	}
	if len(parts) > 2 {
		detail.http = parts[2]
	}
	if len(parts) > 3 {
		detail.count = parts[3]
	}
	return detail
}

// detailMatchScore rewards rendered details after a structural match, rather
// than requiring the canonical key to match exactly. This lets an omitted
// name matcher retain its wildcard behavior while still selecting the
// alternative with the closest status, HTTP response, and cardinality.
func detailMatchScore(leftKey, rightKey string) int {
	left, right := parseSpanDetail(leftKey), parseSpanDetail(rightKey)
	if spanMatchScore(left.node, right.node) < 0 {
		return -1
	}
	score := 0
	if left.status == right.status {
		score += 4
	}
	if left.http == right.http {
		score += 2
	}
	if left.count == right.count {
		score++
	}
	return score
}

func sortedCountKeys(values map[string]int) []string {
	keys := make([]string, 0, len(values))
	for key := range values {
		keys = append(keys, key)
	}
	sort.Strings(keys)
	return keys
}

func consumeCompatibleDetails(details, available map[string]int) (int, map[string]int) {
	consumed := map[string]int{}
	total := 0
	availableKeys := sortedCountKeys(available)
	for _, detailKey := range sortedCountKeys(details) {
		for remaining := details[detailKey]; remaining > 0; remaining-- {
			bestKey, bestScore := "", 0
			for _, oppositeKey := range availableKeys {
				if available[oppositeKey]-consumed[oppositeKey] <= 0 {
					continue
				}
				score := detailMatchScore(detailKey, oppositeKey)
				if score > bestScore || (score == bestScore && score > 0 && (bestKey == "" || oppositeKey < bestKey)) {
					bestKey, bestScore = oppositeKey, score
				}
			}
			if bestScore == 0 {
				break
			}
			consumed[bestKey]++
			total += bestScore
		}
	}
	return total, consumed
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
			detailDelta, detailConsumed := consumeCompatibleDetails(details, detailAvailable)
			delta += detailDelta
			for candidateKey := range keys {
				available[candidateKey] -= consumed[candidateKey]
			}
			for candidateKey, count := range consumed {
				if _, direct := keys[candidateKey]; !direct {
					available[candidateKey] -= count
				}
			}
			for detailKey, count := range detailConsumed {
				detailAvailable[detailKey] -= count
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
	leftKeys, rightKeys := candidateKeys(left.childGroups), candidateKeys(right.childGroups)
	leftDetails, rightDetails := candidateDetailKeys(left.childGroups), candidateDetailKeys(right.childGroups)
	return chooseCandidates(left.childGroups, rightKeys, rightDetails), chooseCandidates(right.childGroups, leftKeys, leftDetails)
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
	index    int
	card     string
	minCount int
	maxCount int
	exact    bool
	altCount int
	coverage string
	roots    []alignedSpan
	label    string
}

func canonicalTraceKey(trace resolvedTrace) string {
	roots := make([]string, 0, len(trace.roots))
	for _, root := range trace.roots {
		roots = append(roots, canonicalSpanKey(root))
	}
	sort.Strings(roots)
	return strings.Join([]string{trace.card, trace.coverage, strings.Join(roots, "\x1e")}, "\x1f")
}

func traceGroupCandidates(index int, group TraceGroup, opposite, oppositeDetails map[string]int) []resolvedTrace {
	if len(group.Alternatives) > 0 {
		var candidates []resolvedTrace
		for _, alternative := range group.Alternatives {
			for _, candidate := range traceGroupCandidates(index, alternative, opposite, oppositeDetails) {
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
			detailDelta, detailConsumed := consumeCompatibleDetails(details, detailAvailable)
			delta += detailDelta
			for item, count := range consumed {
				available[item] -= count
			}
			for item, count := range detailConsumed {
				detailAvailable[item] -= count
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
