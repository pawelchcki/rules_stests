package report

import (
	"flag"
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func exactSpan(scope, kind, status, name, httpStatus string, children ...SpanGroup) SpanGroup {
	return SpanGroup{Count: 1, ExactCount: true, MinCount: 1, MaxCount: 1, Span: SpanNode{Scope: scope, Kind: kind, Status: status, Name: name, HTTPStatus: httpStatus, Children: children}}
}

func repeated(count int, group SpanGroup) SpanGroup {
	group.Count, group.MinCount, group.MaxCount, group.ExactCount = count, count, count, true
	return group
}

func shapeOf(profile string, roots ...SpanGroup) *ScenarioShape {
	return &ScenarioShape{Profile: profile, Scenario: "case", ExactCounts: true, Traces: []TraceGroup{{Count: 1, MinCount: 1, MaxCount: 1, ExactCount: true, Coverage: "complete", Roots: roots}}}
}

func findRow(t *testing.T, alignment *ShapeAlignment, name string) SpanMatch {
	t.Helper()
	for _, trace := range alignment.Traces {
		for _, row := range trace.Spans {
			if (row.Left != nil && row.Left.Name == name) || (row.Right != nil && row.Right.Name == name) {
				return row
			}
		}
	}
	t.Fatalf("no aligned row for %q", name)
	return SpanMatch{}
}

func TestLargeTraceAlignmentUsesBoundedPairing(t *testing.T) {
	left := &ScenarioShape{ExactCounts: true}
	right := &ScenarioShape{ExactCounts: true}
	for i := 0; i < optimalAssignmentVertexLimit/2+1; i++ {
		name := fmt.Sprintf("root-%03d", i)
		group := TraceGroup{Count: 1, ExactCount: true, Coverage: "complete", Roots: []SpanGroup{exactSpan("", "server", "", name, "")}}
		left.Traces = append(left.Traces, group)
		right.Traces = append(right.Traces, group)
	}
	alignment := AlignShapes(left, right)
	if alignment.Summary.TraceMatched != len(left.Traces) || alignment.Summary.TraceLeftOnly != 0 || alignment.Summary.TraceRightOnly != 0 {
		t.Fatalf("bounded trace pairing lost exact matches: %+v", alignment.Summary)
	}
}

func TestLargeTraceAlignmentUsesDescendantStructure(t *testing.T) {
	const count = optimalAssignmentVertexLimit/2 + 1
	left := &ScenarioShape{ExactCounts: true}
	right := &ScenarioShape{ExactCounts: true}
	for i := 0; i < count; i++ {
		group := TraceGroup{Count: 1, ExactCount: true, Coverage: "complete", Roots: []SpanGroup{exactSpan("", "server", "", "root", "", exactSpan("", "client", "", fmt.Sprintf("child-%03d", i), ""))}}
		left.Traces = append(left.Traces, group)
		right.Traces = append([]TraceGroup{group}, right.Traces...)
	}
	alignment := AlignShapes(left, right)
	if alignment.Summary.TraceMatched != count || alignment.Summary.TraceLeftOnly != 0 || alignment.Summary.TraceRightOnly != 0 || alignment.Summary.Differing != 0 || alignment.Summary.LeftOnly != 0 || alignment.Summary.RightOnly != 0 {
		t.Fatalf("large reordered traces ignored descendant structure: %#v", alignment.Summary)
	}
}

func TestLargeMultiRootTraceAlignmentScoresEveryRoot(t *testing.T) {
	const count = optimalAssignmentVertexLimit/2 + 1
	left := &ScenarioShape{ExactCounts: true}
	right := &ScenarioShape{ExactCounts: true}
	for i := 0; i < count; i++ {
		common := exactSpan("", "server", "unset", "common", "")
		child := exactSpan("", "client", "unset", fmt.Sprintf("child-%03d", i), "")
		leftDetail := exactSpan("", "server", "unset", "detail", "", child)
		rightDetail := exactSpan("", "server", "error", "detail", "", child)
		leftTrace := TraceGroup{Count: 1, ExactCount: true, Coverage: "complete", Roots: []SpanGroup{common, leftDetail}}
		rightTrace := TraceGroup{Count: 1, ExactCount: true, Coverage: "complete", Roots: []SpanGroup{common, rightDetail}}
		left.Traces = append(left.Traces, leftTrace)
		right.Traces = append([]TraceGroup{rightTrace}, right.Traces...)
	}
	alignment := AlignShapes(left, right)
	if alignment.Summary.TraceMatched != count || alignment.Summary.TraceLeftOnly != 0 || alignment.Summary.TraceRightOnly != 0 || alignment.Summary.Matched != count*3 || alignment.Summary.Differing != count || alignment.Summary.LeftOnly != 0 || alignment.Summary.RightOnly != 0 {
		t.Fatalf("large multi-root pairing ignored secondary roots: %#v", alignment.Summary)
	}
}

func TestLargePairingPreservesMaximumCardinality(t *testing.T) {
	count := optimalAssignmentVertexLimit/2 + 1
	matched, _ := maximumWeightMaximumCardinalityPairs(count, count, func(left, right int) (int, bool) {
		switch {
		case left == 0 && right == 0:
			return 10, true
		case left == 0 && right == 1:
			return 9, true
		case left == 1 && right == 0:
			return 1, true
		default:
			return 1, left == right
		}
	})
	for left, right := range matched {
		if right < 0 {
			t.Fatalf("large maximum-cardinality pairing left %d unmatched: %v", left, matched)
		}
	}
}

func TestLargeExactSeedsRemainAugmentable(t *testing.T) {
	leftRoots := []SpanGroup{
		exactSpan("", "server", "", "", ""),
		exactSpan("", "server", "", "A", ""),
	}
	rightRoots := []SpanGroup{
		exactSpan("", "server", "", "", ""),
		exactSpan("", "server", "", "B", ""),
	}
	for i := 0; i < optimalAssignmentVertexLimit/2-1; i++ {
		common := exactSpan("", "server", "", fmt.Sprintf("common-%03d", i), "")
		leftRoots = append(leftRoots, common)
		rightRoots = append(rightRoots, common)
	}
	alignment := AlignShapes(shapeOf("left", leftRoots...), shapeOf("right", rightRoots...))
	if alignment.Summary.Matched != len(leftRoots) || alignment.Summary.LeftOnly != 0 || alignment.Summary.RightOnly != 0 {
		t.Fatalf("exact seeds blocked a maximum-cardinality wildcard pairing: %#v", alignment.Summary)
	}
}

func TestLargeAssignmentAllowsThreeWayScoreImprovement(t *testing.T) {
	parent := func(children ...int) SpanGroup {
		groups := make([]SpanGroup, 0, len(children))
		for _, child := range children {
			groups = append(groups, exactSpan("", "client", "", fmt.Sprintf("child-%d", child), ""))
		}
		return exactSpan("", "internal", "", "parent", "", groups...)
	}
	leftRoots := []SpanGroup{
		parent(0, 1, 4, 5),
		parent(2, 4, 5),
		parent(0, 2, 4, 5),
	}
	rightRoots := []SpanGroup{
		parent(0, 1, 2, 3),
		parent(1, 5),
		parent(5),
	}
	for i := 0; i < optimalAssignmentVertexLimit/2-2; i++ {
		common := exactSpan("", "server", "", fmt.Sprintf("common-%03d", i), "")
		leftRoots = append(leftRoots, common)
		rightRoots = append(rightRoots, common)
	}
	shape := func(profile string, children []SpanGroup) *ScenarioShape {
		return shapeOf(profile, exactSpan("", "server", "", "root", "", children...))
	}
	alignment := AlignShapes(shape("left", leftRoots), shape("right", rightRoots))
	if alignment.Summary.Matched != 71 {
		t.Fatalf("three-way score improvement was missed: %#v", alignment.Summary)
	}
}

func TestLargeAssignmentOptimizesUnmatchedCandidates(t *testing.T) {
	wildcard := exactSpan("", "server", "", "", "")
	concrete := exactSpan("", "server", "", "A", "")
	common := make([]SpanGroup, optimalAssignmentVertexLimit/2)
	for i := range common {
		common[i] = exactSpan("", "server", "", fmt.Sprintf("common-%03d", i), "")
	}
	shape := func(profile string, children []SpanGroup) *ScenarioShape {
		return shapeOf(profile, exactSpan("", "server", "", "root", "", children...))
	}
	assertConcretePair := func(t *testing.T, alignment *ShapeAlignment, leftOnly, rightOnly int) {
		t.Helper()
		row := findRow(t, alignment, "A")
		if row.Kind != "matched" || row.Left == nil || row.Right == nil || row.Left.Name != "A" || row.Right.Name != "A" || alignment.Summary.LeftOnly != leftOnly || alignment.Summary.RightOnly != rightOnly {
			t.Fatalf("unmatched candidate was excluded from score optimization: row=%#v summary=%#v", row, alignment.Summary)
		}
	}
	t.Run("unmatched right", func(t *testing.T) {
		left := append([]SpanGroup{concrete}, common...)
		right := append([]SpanGroup{wildcard}, common...)
		right = append(right, concrete)
		assertConcretePair(t, AlignShapes(shape("left", left), shape("right", right)), 0, 1)
	})
	t.Run("unmatched left", func(t *testing.T) {
		left := append([]SpanGroup{wildcard}, common...)
		left = append(left, concrete)
		right := append([]SpanGroup{concrete}, common...)
		assertConcretePair(t, AlignShapes(shape("left", left), shape("right", right)), 1, 0)
	})
}

func TestLargeSiblingAlignmentUsesChildStructure(t *testing.T) {
	const count = optimalAssignmentVertexLimit/2 + 1
	leftParents := make([]SpanGroup, 0, count)
	rightParents := make([]SpanGroup, 0, count)
	for i := 0; i < count; i++ {
		parent := exactSpan("", "internal", "", "parent", "", exactSpan("", "client", "", fmt.Sprintf("child-%03d", i), ""))
		leftParents = append(leftParents, parent)
		rightParents = append([]SpanGroup{parent}, rightParents...)
	}
	root := func(children []SpanGroup) *ScenarioShape {
		return shapeOf("profile", exactSpan("", "server", "", "root", "", children...))
	}
	exact, _ := bestShallowSpanPair(leftParents[0], rightParents[count-1])
	mismatch, _ := bestShallowSpanPair(leftParents[0], rightParents[0])
	if exact.score <= mismatch.score {
		t.Fatalf("child-aware shallow score did not prefer exact subtree: %d <= %d", exact.score, mismatch.score)
	}
	alignment := AlignShapes(root(leftParents), root(rightParents))
	if alignment.Summary.Differing != 0 || alignment.Summary.LeftOnly != 0 || alignment.Summary.RightOnly != 0 || alignment.Summary.Matched != 1+count*2 {
		t.Fatalf("large reordered parents ignored child structure: %#v", alignment.Summary)
	}
}

func TestNestedPairScoringBoundsExactChildAssignments(t *testing.T) {
	children := func(reverse bool) []SpanGroup {
		groups := make([]SpanGroup, 0, nestedScoreVertexLimit/2+1)
		for i := 0; i < nestedScoreVertexLimit/2+1; i++ {
			child := exactSpan("", "client", "", fmt.Sprintf("child-%02d", i), "")
			if reverse {
				groups = append([]SpanGroup{child}, groups...)
			} else {
				groups = append(groups, child)
			}
		}
		return groups
	}
	left := resolveSpanGroup(exactSpan("", "internal", "", "parent", "", children(false)...))[0]
	right := resolveSpanGroup(exactSpan("", "internal", "", "parent", "", children(true)...))[0]
	want := shallowAlignedSpanMatchScore(left, right) + childOverlapScore(left, right)
	if got := alignedSpanMatchScore(left, right); got != want {
		t.Fatalf("large nested candidate used recursive exact scoring: got %d, want bounded score %d", got, want)
	}
}

func TestNestedPairScoringRetainsPartialDescendantOverlap(t *testing.T) {
	parent := func(shared, unique string) alignedSpan {
		children := make([]SpanGroup, 0, nestedScoreVertexLimit/2+1)
		for i := 0; i < nestedScoreVertexLimit/2+1; i++ {
			marker := fmt.Sprintf("%s-%02d", unique, i)
			if i < 4 {
				marker = fmt.Sprintf("%s-%02d", shared, i)
			}
			children = append(children, exactSpan("", "internal", "", "branch", "", exactSpan("", "client", "", marker, "")))
		}
		return resolveSpanGroup(exactSpan("", "server", "", "parent", "", children...))[0]
	}
	left := parent("shared", "left")
	closer := parent("shared", "right")
	farther := parent("other", "farther")
	if got, want := alignedSpanMatchScore(left, closer), alignedSpanMatchScore(left, farther); got <= want {
		t.Fatalf("bounded descendant score did not prefer partial deeper overlap: %d <= %d", got, want)
	}
}

func TestLargeSiblingAlignmentUsesPartialChildOverlap(t *testing.T) {
	const count = optimalAssignmentVertexLimit/2 + 1
	leftParents := make([]SpanGroup, 0, count)
	rightParents := make([]SpanGroup, 0, count)
	for i := 0; i < count; i++ {
		marker := exactSpan("", "client", "", fmt.Sprintf("marker-%03d", i), "")
		left := exactSpan("", "internal", "", "parent", "", marker, exactSpan("", "client", "", "left-only", ""))
		right := exactSpan("", "internal", "", "parent", "", marker, exactSpan("", "client", "", "right-only", ""))
		leftParents = append(leftParents, left)
		rightParents = append([]SpanGroup{right}, rightParents...)
	}
	root := func(children []SpanGroup) *ScenarioShape {
		return shapeOf("profile", exactSpan("", "server", "", "root", "", children...))
	}
	alignment := AlignShapes(root(leftParents), root(rightParents))
	if alignment.Summary.Matched != 1+count*2 || alignment.Summary.LeftOnly != count || alignment.Summary.RightOnly != count {
		t.Fatalf("large parents ignored partial child overlap: %#v", alignment.Summary)
	}
}

func TestLargeTraceAlignmentUsesPartialDescendantOverlap(t *testing.T) {
	const count = optimalAssignmentVertexLimit/2 + 1
	left := &ScenarioShape{ExactCounts: true}
	right := &ScenarioShape{ExactCounts: true}
	for i := 0; i < count; i++ {
		marker := exactSpan("", "client", "", fmt.Sprintf("marker-%03d", i), "")
		trace := func(side string) TraceGroup {
			return TraceGroup{Count: 1, ExactCount: true, Coverage: "complete", Roots: []SpanGroup{exactSpan("", "server", "", "root", "", marker, exactSpan("", "client", "", side, ""))}}
		}
		left.Traces = append(left.Traces, trace("left-only"))
		right.Traces = append([]TraceGroup{trace("right-only")}, right.Traces...)
	}
	alignment := AlignShapes(left, right)
	if alignment.Summary.TraceMatched != count || alignment.Summary.Matched != count*2 || alignment.Summary.LeftOnly != count || alignment.Summary.RightOnly != count {
		t.Fatalf("large traces ignored partial descendant overlap: %#v", alignment.Summary)
	}
}

func TestNormalizeSpanNameCollapsesRouteParameters(t *testing.T) {
	tests := map[string]string{
		"GET /api/articles/<slug>":    "get api/articles/*",
		"GET api/articles/<slug>":     "get api/articles/*",
		"GET /api/articles/:slug":     "get api/articles/*",
		"GET /api/articles/{slug}":    "get api/articles/*",
		"GET /api/articles/%{slug}":   "get api/articles/*",
		"GET   /api/tags":             "get api/tags",
		"SELECT  …  articles_tag":     "select … articles_tag",
		"SELECT value::text":          "select value::text",
		"SELECT value::integer":       "select value::integer",
		"SELECT data/{tenant}":        "select data/{tenant}",
		"SELECT '{\"tenant\":\"a\"}'": "select '{\"tenant\":\"a\"}'",
	}
	for input, want := range tests {
		if got := NormalizeSpanName(input); got != want {
			t.Errorf("NormalizeSpanName(%q) = %q, want %q", input, got, want)
		}
	}
}

func TestAlignShapesResolvesNestedChoicesAgainstPairedParents(t *testing.T) {
	a := exactSpan("", "client", "unset", "A", "200")
	b := exactSpan("", "client", "unset", "B", "200")
	choice := SpanGroup{Cardinality: "one_of", MinCount: 1, MaxCount: 1, Alternatives: []SpanGroup{a, b}}
	p1 := func(children ...SpanGroup) SpanGroup {
		return exactSpan("", "server", "unset", "P1", "200", children...)
	}
	p2 := func(children ...SpanGroup) SpanGroup {
		return exactSpan("", "server", "unset", "P2", "200", children...)
	}
	alignment := AlignShapes(shapeOf("left", p1(choice), p2(a)), shapeOf("right", p1(b), p2(a)))
	if alignment.Summary.Matched != 4 || alignment.Summary.Differing != 1 || alignment.Summary.LeftOnly != 0 || alignment.Summary.RightOnly != 0 {
		t.Fatalf("nested choice was resolved before its parent pair: %#v", alignment.Summary)
	}
	if row := findRow(t, alignment, "B"); row.Kind != "matched" || strings.Join(row.Diffs, ",") != "count" {
		t.Fatalf("nested choice did not retain the paired child's only count difference: %#v", row)
	}
}

func TestAlignShapesPairsReorderedDuplicateSiblingsByDetails(t *testing.T) {
	ok := exactSpan("http", "client", "unset", "GET item", "200")
	notFound := repeated(2, exactSpan("http", "client", "error", "GET item", "404"))
	root := func(children ...SpanGroup) SpanGroup {
		return exactSpan("server", "server", "unset", "GET /api/items", "200", children...)
	}
	left := shapeOf("left", root(ok, notFound))
	right := shapeOf("right", root(notFound, ok))
	alignment := AlignShapes(left, right)
	if alignment.Summary.Matched != 3 || alignment.Summary.Differing != 0 || alignment.Summary.LeftOnly != 0 || alignment.Summary.RightOnly != 0 {
		t.Fatalf("reordered duplicate siblings did not align by details: %#v", alignment.Summary)
	}
	for _, row := range alignment.Traces[0].Spans {
		if row.Kind == "matched" && len(row.Diffs) != 0 {
			t.Fatalf("equivalent sibling pair was reported as different: %#v", row)
		}
	}
}

func TestAlignShapesBreaksScoreTiesIndependentlyOfSiblingOrder(t *testing.T) {
	leftChildren := []SpanGroup{
		exactSpan("", "client", "", "request", ""),
		exactSpan("", "client", "ok", "request", "200"),
	}
	rightChildren := []SpanGroup{
		exactSpan("", "client", "", "request", "500"),
		exactSpan("", "client", "error", "request", ""),
	}
	root := func(children ...SpanGroup) SpanGroup {
		return exactSpan("", "server", "", "root", "", children...)
	}
	pairings := func(alignment *ShapeAlignment) string {
		pairs := []string{}
		for _, row := range alignment.Traces[0].Spans {
			if row.Depth != 1 || row.Left == nil || row.Right == nil {
				continue
			}
			pairs = append(pairs, strings.Join([]string{
				row.Left.Status, row.Left.HTTPStatus,
				row.Right.Status, row.Right.HTTPStatus,
				strings.Join(row.Diffs, ","),
			}, "/"))
		}
		return strings.Join(pairs, "|")
	}
	forward := pairings(AlignShapes(shapeOf("left", root(leftChildren...)), shapeOf("right", root(rightChildren...))))
	reversed := pairings(AlignShapes(shapeOf("left", root(leftChildren...)), shapeOf("right", root(rightChildren[1], rightChildren[0]))))
	if forward != reversed {
		t.Fatalf("score-tied sibling assignment depended on right order: %q != %q", forward, reversed)
	}
}

func TestAlignShapesPrefersWildcardSiblingsWithMatchingSpecificity(t *testing.T) {
	unnamed := exactSpan("", "server", "error", "", "500")
	named := exactSpan("", "server", "error", "B", "500")
	root := func(children ...SpanGroup) SpanGroup {
		return exactSpan("", "server", "unset", "GET /items", "200", children...)
	}
	alignment := AlignShapes(shapeOf("left", root(unnamed, named)), shapeOf("right", root(unnamed, named)))
	if alignment.Summary.Differing != 0 || alignment.Summary.LeftOnly != 0 || alignment.Summary.RightOnly != 0 {
		t.Fatalf("wildcard siblings were cross-paired: %#v", alignment.Summary)
	}
}

func TestAlignShapesPrefersEquallyUnspecifiedSiblingKinds(t *testing.T) {
	unnamed := exactSpan("", "", "error", "A", "500")
	server := exactSpan("", "server", "error", "A", "500")
	root := func(children ...SpanGroup) SpanGroup {
		return exactSpan("", "server", "unset", "GET /items", "200", children...)
	}
	alignment := AlignShapes(shapeOf("left", root(unnamed, server)), shapeOf("right", root(unnamed, server)))
	if alignment.Summary.Differing != 0 || alignment.Summary.LeftOnly != 0 || alignment.Summary.RightOnly != 0 {
		t.Fatalf("wildcard kinds were cross-paired: %#v", alignment.Summary)
	}
}

func TestAlignShapesMaximizesSiblingDetailScoreGlobally(t *testing.T) {
	unnamedError := exactSpan("", "server", "error", "", "500")
	namedError := exactSpan("", "server", "error", "A", "500")
	unnamedUnset := exactSpan("", "server", "unset", "", "500")
	root := func(children ...SpanGroup) SpanGroup {
		return exactSpan("", "server", "unset", "GET /items", "200", children...)
	}
	alignment := AlignShapes(shapeOf("left", root(unnamedError, namedError)), shapeOf("right", root(namedError, unnamedUnset)))
	if alignment.Summary.Differing != 1 || alignment.Summary.LeftOnly != 0 || alignment.Summary.RightOnly != 0 {
		t.Fatalf("sibling pairing did not maximize aggregate detail score: %#v", alignment.Summary)
	}
	if row := findRow(t, alignment, "A"); row.Left == nil || row.Right == nil || row.Left.Name != "A" || row.Right.Name != "A" {
		t.Fatalf("specific sibling was not retained in its equivalent pair: %#v", row)
	}
}

func TestAlignShapesMinimizesDifferingRowsSymmetrically(t *testing.T) {
	clientB := exactSpan("", "client", "unset", "B", "")
	anyKindB := exactSpan("", "", "unset", "B", "")
	clientUnnamed := exactSpan("", "client", "", "", "")
	left := shapeOf("left", clientB, anyKindB)
	right := shapeOf("right", clientUnnamed, clientB)
	for _, pair := range [][2]*ScenarioShape{{left, right}, {right, left}} {
		alignment := AlignShapes(pair[0], pair[1])
		if alignment.Summary.Matched != 2 || alignment.Summary.Differing != 1 || alignment.Summary.LeftOnly != 0 || alignment.Summary.RightOnly != 0 {
			t.Fatalf("rendered-difference tie-break depended on orientation: %#v", alignment.Summary)
		}
		for _, row := range alignment.Traces[0].Spans {
			if row.Left != nil && row.Right != nil && row.Left.Name == "B" && row.Right.Name == "B" && row.Left.Kind == "client" && row.Right.Kind == "client" && len(row.Diffs) != 0 {
				t.Fatalf("identical concrete spans were not paired: %#v", row)
			}
		}
	}
}

func TestAlignShapesChoosesWildcardAlternativeByDetails(t *testing.T) {
	unnamedError := exactSpan("", "server", "error", "", "500")
	unnamedUnset := exactSpan("", "server", "unset", "", "500")
	choice := SpanGroup{Cardinality: "one_of", MinCount: 1, MaxCount: 1, Alternatives: []SpanGroup{unnamedError, unnamedUnset}}
	root := func(children ...SpanGroup) SpanGroup {
		return exactSpan("", "server", "unset", "GET /items", "200", children...)
	}
	left := shapeOf("left", root(choice))
	right := shapeOf("right", root(exactSpan("", "server", "unset", "A", "500")))
	row := findRow(t, AlignShapes(left, right), "A")
	if row.Kind != "matched" || strings.Contains(strings.Join(row.Diffs, ","), "status") {
		t.Fatalf("wildcard alternative ignored its matching status: %#v", row)
	}
}

func TestAlignShapesRewardsEquallyUnspecifiedDetails(t *testing.T) {
	concrete := exactSpan("", "client", "error", "B", "500")
	unspecifiedClient := exactSpan("", "client", "", "", "")
	unspecifiedKind := exactSpan("", "", "error", "", "500")
	choice := func(alternatives ...SpanGroup) SpanGroup {
		return SpanGroup{Cardinality: "one_of", MinCount: 1, MaxCount: 1, Alternatives: alternatives}
	}
	left := shapeOf("left", choice(concrete, unspecifiedClient))
	right := shapeOf("right", choice(unspecifiedClient, unspecifiedKind))
	for _, pair := range [][2]*ScenarioShape{{left, right}, {right, left}} {
		alignment := AlignShapes(pair[0], pair[1])
		if alignment.Summary.Matched != 1 || alignment.Summary.Differing != 0 || alignment.Summary.LeftOnly != 0 || alignment.Summary.RightOnly != 0 {
			t.Fatalf("unspecified alternatives were resolved asymmetrically: %#v", alignment.Summary)
		}
	}
}

func TestAlignShapesPrefersTraceGroupsWithTheSameRootSet(t *testing.T) {
	a := exactSpan("", "server", "unset", "A", "200")
	b := exactSpan("", "server", "unset", "B", "200")
	c := exactSpan("", "server", "unset", "C", "200")
	trace := func(roots ...SpanGroup) TraceGroup {
		return TraceGroup{Count: 1, ExactCount: true, MinCount: 1, MaxCount: 1, Coverage: "complete", Roots: roots}
	}
	left := &ScenarioShape{Traces: []TraceGroup{trace(a), trace(a, b, c)}}
	right := &ScenarioShape{Traces: []TraceGroup{trace(a, b, c), trace(a)}}
	alignment := AlignShapes(left, right)
	if alignment.Summary.TraceMatched != 2 || alignment.Summary.LeftOnly != 0 || alignment.Summary.RightOnly != 0 {
		t.Fatalf("trace groups were cross-paired: %#v", alignment.Summary)
	}
}

func TestAlignShapesCarriesTraceCoverageDifferences(t *testing.T) {
	root := exactSpan("", "server", "unset", "GET /items", "200")
	left := &ScenarioShape{Traces: []TraceGroup{{Count: 1, ExactCount: true, MinCount: 1, MaxCount: 1, Coverage: "complete", Roots: []SpanGroup{root}}}}
	right := &ScenarioShape{Traces: []TraceGroup{{Count: 1, ExactCount: true, MinCount: 1, MaxCount: 1, Coverage: "partial", Roots: []SpanGroup{root}}}}
	alignment := AlignShapes(left, right)
	match := alignment.Traces[0]
	if match.Left.Coverage != "complete" || match.Right.Coverage != "partial" {
		t.Fatalf("trace coverage was omitted from alignment: %#v", match)
	}
}

func TestAlignShapesPrefersTraceGroupsWithMatchingMetadata(t *testing.T) {
	root := exactSpan("", "server", "unset", "GET /items", "200")
	trace := func(count int, coverage string) TraceGroup {
		return TraceGroup{Count: count, ExactCount: true, MinCount: count, MaxCount: count, Coverage: coverage, Roots: []SpanGroup{root}}
	}
	left := &ScenarioShape{Traces: []TraceGroup{trace(1, "complete"), trace(2, "partial")}}
	right := &ScenarioShape{Traces: []TraceGroup{trace(2, "partial"), trace(1, "complete")}}
	alignment := AlignShapes(left, right)
	if alignment.Summary.TraceMatched != 2 || alignment.Summary.Differing != 0 {
		t.Fatalf("trace groups were not paired by matching metadata: %#v", alignment.Summary)
	}
	for _, match := range alignment.Traces {
		if match.Left.Card != match.Right.Card || match.Left.Coverage != match.Right.Coverage {
			t.Fatalf("trace metadata was cross-paired: %#v", match)
		}
	}
}

func TestAlignShapesPreservesTraceChoiceThroughCardinalityWrapper(t *testing.T) {
	a := exactSpan("", "server", "unset", "A", "200")
	b := exactSpan("", "server", "unset", "B", "200")
	trace := func(root SpanGroup) TraceGroup {
		return TraceGroup{Count: 1, ExactCount: true, MinCount: 1, MaxCount: 1, Coverage: "complete", Roots: []SpanGroup{root}}
	}
	choice := TraceGroup{Cardinality: "one_of", MinCount: 1, MaxCount: 1, Alternatives: []TraceGroup{trace(a), trace(b)}}
	optional := TraceGroup{Cardinality: "optional", MinCount: 0, MaxCount: 1, Alternatives: []TraceGroup{choice}}
	left := &ScenarioShape{Traces: []TraceGroup{optional}}
	right := &ScenarioShape{Traces: []TraceGroup{trace(a)}}
	alignment := AlignShapes(left, right)
	if len(alignment.Traces) != 1 || alignment.Traces[0].Left.Card != "one of 2 · optional" {
		t.Fatalf("wrapped trace choice label was lost: %#v", alignment.Traces)
	}
}

func TestAlignShapesPairsDuplicateParentsByChildSubtree(t *testing.T) {
	childA := exactSpan("worker", "consumer", "unset", "receive a", "")
	childB := exactSpan("worker", "consumer", "unset", "receive b", "")
	parent := func(child SpanGroup) SpanGroup {
		return exactSpan("server", "internal", "unset", "process item", "", child)
	}
	root := func(children ...SpanGroup) SpanGroup {
		return exactSpan("server", "server", "unset", "GET /api/items", "200", children...)
	}
	left := shapeOf("left", root(parent(childA), parent(childB)))
	right := shapeOf("right", root(parent(childB), parent(childA)))
	alignment := AlignShapes(left, right)
	if alignment.Summary.Matched != 5 || alignment.Summary.Differing != 0 || alignment.Summary.LeftOnly != 0 || alignment.Summary.RightOnly != 0 {
		t.Fatalf("reordered duplicate parents did not keep child subtrees together: %#v", alignment.Summary)
	}
}

func TestAlignShapesScoresPartialChildSubtreeMatches(t *testing.T) {
	a := exactSpan("", "client", "unset", "A", "")
	b := exactSpan("", "client", "unset", "B", "")
	c := exactSpan("", "client", "unset", "C", "")
	d := exactSpan("", "client", "unset", "D", "")
	parent := func(children ...SpanGroup) SpanGroup {
		return exactSpan("", "server", "unset", "P", "", children...)
	}
	choice := SpanGroup{Cardinality: "one_of", MinCount: 1, MaxCount: 1, Alternatives: []SpanGroup{
		parent(a, c),
		parent(b, c),
	}}
	alignment := AlignShapes(shapeOf("left", choice), shapeOf("right", parent(b, d)))
	if alignment.Summary.Matched != 2 || alignment.Summary.LeftOnly != 1 || alignment.Summary.RightOnly != 1 {
		t.Fatalf("partial child overlap did not select the better parent alternative: %#v", alignment.Summary)
	}
	if row := findRow(t, alignment, "B"); row.Kind != "matched" || row.Left == nil || row.Right == nil {
		t.Fatalf("shared child was not retained: %#v", row)
	}
}

func TestAlignShapesHandlesManyIndependentAlternatives(t *testing.T) {
	const groupCount = 12
	leftChildren := make([]SpanGroup, 0, groupCount)
	rightChildren := make([]SpanGroup, 0, groupCount)
	for index := 0; index < groupCount; index++ {
		first := exactSpan("", "client", "unset", fmt.Sprintf("A-%02d", index), "")
		second := exactSpan("", "client", "unset", fmt.Sprintf("B-%02d", index), "")
		leftChildren = append(leftChildren, SpanGroup{Cardinality: "one_of", MinCount: 1, MaxCount: 1, Alternatives: []SpanGroup{first, second}})
		rightChildren = append(rightChildren, SpanGroup{Cardinality: "one_of", MinCount: 1, MaxCount: 1, Alternatives: []SpanGroup{second, first}})
	}
	root := func(children []SpanGroup) SpanGroup {
		return exactSpan("", "server", "unset", "root", "", children...)
	}
	alignment := AlignShapes(shapeOf("left", root(leftChildren)), shapeOf("right", root(rightChildren)))
	if alignment.Summary.Matched != groupCount+1 || alignment.Summary.LeftOnly != 0 || alignment.Summary.RightOnly != 0 {
		t.Fatalf("independent alternatives did not align: %#v", alignment.Summary)
	}
}

func TestAlignShapesHandlesManyIndependentTraceAlternatives(t *testing.T) {
	const groupCount = 12
	leftTraces := make([]TraceGroup, 0, groupCount)
	rightTraces := make([]TraceGroup, 0, groupCount)
	trace := func(root SpanGroup) TraceGroup {
		return TraceGroup{Count: 1, ExactCount: true, MinCount: 1, MaxCount: 1, Roots: []SpanGroup{root}}
	}
	for index := 0; index < groupCount; index++ {
		first := trace(exactSpan("", "server", "unset", fmt.Sprintf("GET /a/%02d", index), "200"))
		second := trace(exactSpan("", "server", "unset", fmt.Sprintf("GET /b/%02d", index), "200"))
		leftTraces = append(leftTraces, TraceGroup{Cardinality: "one_of", MinCount: 1, MaxCount: 1, Alternatives: []TraceGroup{first, second}})
		rightTraces = append(rightTraces, TraceGroup{Cardinality: "one_of", MinCount: 1, MaxCount: 1, Alternatives: []TraceGroup{second, first}})
	}
	alignment := AlignShapes(&ScenarioShape{Traces: leftTraces}, &ScenarioShape{Traces: rightTraces})
	if alignment.Summary.TraceMatched != groupCount || alignment.Summary.TraceLeftOnly != 0 || alignment.Summary.TraceRightOnly != 0 {
		t.Fatalf("independent trace alternatives did not align: %#v", alignment.Summary)
	}
}

func TestAlignShapesMatchesReorderedMultiRootTraces(t *testing.T) {
	first := exactSpan("consumer", "consumer", "unset", "receive alpha", "absent")
	second := exactSpan("consumer", "consumer", "unset", "receive beta", "absent")
	left := shapeOf("left", first, second)
	right := shapeOf("right", second, first)
	alignment := AlignShapes(left, right)
	if alignment.Summary.TraceMatched != 1 || alignment.Summary.TraceLeftOnly != 0 || alignment.Summary.TraceRightOnly != 0 {
		t.Fatalf("reordered multi-root traces did not align: %#v", alignment.Summary)
	}
	if alignment.Summary.Matched != 2 || alignment.Summary.LeftOnly != 0 || alignment.Summary.RightOnly != 0 {
		t.Fatalf("reordered roots did not align as an unordered set: %#v", alignment.Summary)
	}
}

func TestAlignShapesCoordinatesSiblingOneOfChoices(t *testing.T) {
	a := exactSpan("worker", "consumer", "unset", "receive a", "absent")
	b := exactSpan("worker", "consumer", "unset", "receive b", "absent")
	choice := SpanGroup{Cardinality: "one_of", MinCount: 1, MaxCount: 1, Alternatives: []SpanGroup{a, b}}
	root := func(children ...SpanGroup) SpanGroup {
		return exactSpan("server", "server", "unset", "GET /api/items", "200", children...)
	}
	left := shapeOf("left", root(choice, a))
	right := shapeOf("right", root(a, b))
	alignment := AlignShapes(left, right)
	if alignment.Summary.Matched != 3 || alignment.Summary.LeftOnly != 0 || alignment.Summary.RightOnly != 0 {
		t.Fatalf("sibling one-of alternatives were not selected jointly: %#v", alignment.Summary)
	}
	if row := findRow(t, alignment, "receive b"); row.Kind != "matched" || row.LeftCard != "one of 2" {
		t.Fatalf("expected the one-of to consume the remaining b span: %#v", row)
	}
}

func TestAlignShapesResolvesAlternativesJointlyAcrossBothShapes(t *testing.T) {
	a := exactSpan("", "server", "unset", "A", "")
	b := exactSpan("", "server", "unset", "B", "")
	c := exactSpan("", "server", "unset", "C", "")
	choice := func(alternatives ...SpanGroup) SpanGroup {
		return SpanGroup{Cardinality: "one_of", MinCount: 1, MaxCount: 1, Alternatives: alternatives}
	}
	left := shapeOf("left", choice(a, b), c)
	right := shapeOf("right", a, choice(b, c))
	alignment := AlignShapes(left, right)
	if alignment.Summary.Matched != 2 || alignment.Summary.LeftOnly != 0 || alignment.Summary.RightOnly != 0 {
		t.Fatalf("alternatives were resolved independently across shapes: %#v", alignment.Summary)
	}
	if row := findRow(t, alignment, "C"); row.Kind != "matched" || row.Left == nil || row.Right == nil {
		t.Fatalf("joint alternative selection did not retain C on both sides: %#v", row)
	}
}

func TestAlignShapesExploresWildcardInventoryAssignments(t *testing.T) {
	wildcard := exactSpan("", "server", "error", "", "")
	a := exactSpan("", "server", "unset", "A", "")
	z := exactSpan("", "server", "error", "Z", "")
	c := exactSpan("", "server", "error", "C", "")
	choice := SpanGroup{Cardinality: "one_of", MinCount: 1, MaxCount: 1, Alternatives: []SpanGroup{z, c}}
	alignment := AlignShapes(shapeOf("left", wildcard, choice), shapeOf("right", a, z))
	if alignment.Summary.Matched != 2 || alignment.Summary.LeftOnly != 0 || alignment.Summary.RightOnly != 0 {
		t.Fatalf("wildcard inventory choice lost a later exact match: %#v", alignment.Summary)
	}
	row := findRow(t, alignment, "Z")
	if row.Kind != "matched" || row.Left == nil || row.Right == nil || row.Left.Name != "Z" || row.Right.Name != "Z" {
		t.Fatalf("wildcard consumed the exact match needed by the later choice: %#v", row)
	}
}

func TestAlignShapesSelectsOneOfAlternativeByDetails(t *testing.T) {
	ok := exactSpan("http", "client", "unset", "GET item", "200")
	failed := exactSpan("http", "client", "error", "GET item", "500")
	choice := SpanGroup{Cardinality: "one_of", MinCount: 1, MaxCount: 1, Alternatives: []SpanGroup{failed, ok}}
	root := func(children ...SpanGroup) SpanGroup {
		return exactSpan("server", "server", "unset", "GET /api/items", "200", children...)
	}
	alignment := AlignShapes(shapeOf("left", root(choice)), shapeOf("right", root(ok)))
	if alignment.Summary.Matched != 2 || alignment.Summary.Differing != 1 || alignment.Summary.LeftOnly != 0 || alignment.Summary.RightOnly != 0 {
		t.Fatalf("one-of choice ignored matching status and HTTP details: %#v", alignment.Summary)
	}
	if row := findRow(t, alignment, "GET item"); len(row.Diffs) != 1 || row.Diffs[0] != "count" {
		t.Fatalf("one-of choice should differ only by its rendered cardinality: %#v", row)
	}
}

func TestAlignShapesPrefersExactRawNameAmongNormalizedAlternatives(t *testing.T) {
	braces := exactSpan("", "server", "unset", "GET /x/{id}", "200")
	colon := exactSpan("", "server", "unset", "GET /x/:id", "200")
	choice := SpanGroup{Cardinality: "one_of", MinCount: 1, MaxCount: 1, Alternatives: []SpanGroup{braces, colon}}
	alignment := AlignShapes(shapeOf("left", choice), shapeOf("right", colon))
	row := findRow(t, alignment, "GET /x/:id")
	if row.Kind != "matched" || strings.Contains(strings.Join(row.Diffs, ","), "name") {
		t.Fatalf("exact raw-name alternative was not preferred: %#v", row)
	}
}

func TestAlignShapesMaximizesWildcardSiblingPairing(t *testing.T) {
	wildcard := exactSpan("", "", "error", "", "500")
	server := exactSpan("", "server", "unset", "", "")
	rightServer := exactSpan("", "server", "error", "GET /api/items", "500")
	rightClient := exactSpan("", "client", "unset", "SELECT items", "")
	root := func(children ...SpanGroup) SpanGroup {
		return exactSpan("server", "server", "unset", "GET /api/items", "200", children...)
	}
	left := shapeOf("left", root(wildcard, server))
	right := shapeOf("right", root(rightServer, rightClient))
	alignment := AlignShapes(left, right)
	if alignment.Summary.Matched != 3 || alignment.Summary.LeftOnly != 0 || alignment.Summary.RightOnly != 0 {
		t.Fatalf("detail scoring sacrificed a compatible sibling match: %#v", alignment.Summary)
	}
}

func TestAlignShapesMaximizesCompatibleTracePairs(t *testing.T) {
	server := exactSpan("", "server", "unset", "GET /api/items", "200")
	client := exactSpan("", "client", "unset", "process item", "")
	wildcard := exactSpan("", "", "unset", "", "")
	trace := func(roots ...SpanGroup) TraceGroup {
		return TraceGroup{Count: 1, ExactCount: true, MinCount: 1, MaxCount: 1, Roots: roots}
	}
	left := &ScenarioShape{Traces: []TraceGroup{
		trace(wildcard, server), // Matches either right trace, with a higher score for the first.
		trace(server),
	}}
	right := &ScenarioShape{Traces: []TraceGroup{
		trace(server, client),
		trace(client),
	}}
	alignment := AlignShapes(left, right)
	if alignment.Summary.TraceMatched != 2 || alignment.Summary.TraceLeftOnly != 0 || alignment.Summary.TraceRightOnly != 0 {
		t.Fatalf("greedy trace choice lost a compatible pair: %#v", alignment.Summary)
	}
}

func TestAlignShapesKeepsSparseRootOverlapCompatible(t *testing.T) {
	shared := exactSpan("", "server", "unset", "GET /shared", "200")
	leftRoots := []SpanGroup{shared}
	for index := 0; index < 11; index++ {
		leftRoots = append(leftRoots, exactSpan("", "client", "unset", fmt.Sprintf("extra-%02d", index), ""))
	}
	alignment := AlignShapes(shapeOf("left", leftRoots...), shapeOf("right", shared))
	if alignment.Summary.TraceMatched != 1 || alignment.Summary.TraceLeftOnly != 0 || alignment.Summary.TraceRightOnly != 0 {
		t.Fatalf("shared root did not keep trace groups compatible: %#v", alignment.Summary)
	}
	if alignment.Summary.Matched != 1 || alignment.Summary.LeftOnly != 11 || alignment.Summary.RightOnly != 0 {
		t.Fatalf("sparse root overlap produced the wrong span alignment: %#v", alignment.Summary)
	}
}

func TestAlignShapesPreservesNegativeTraceScoreOrdering(t *testing.T) {
	shared := exactSpan("", "server", "unset", "X", "200")
	traceWith := func(marker string, side string) TraceGroup {
		roots := []SpanGroup{
			shared,
			exactSpan("", "server", "unset", marker+"-1", "200"),
			exactSpan("", "server", "unset", marker+"-2", "200"),
		}
		for index := 0; index < 20; index++ {
			roots = append(roots, exactSpan("", "client", "unset", fmt.Sprintf("%s-%s-%02d", marker, side, index), ""))
		}
		return TraceGroup{Count: 1, ExactCount: true, MinCount: 1, MaxCount: 1, Roots: roots}
	}
	left := &ScenarioShape{Traces: []TraceGroup{traceWith("A", "left"), traceWith("B", "left")}}
	right := &ScenarioShape{Traces: []TraceGroup{traceWith("B", "right"), traceWith("A", "right")}}
	alignment := AlignShapes(left, right)
	if alignment.Summary.TraceMatched != 2 || alignment.Summary.Matched != 6 || alignment.Summary.LeftOnly != 40 || alignment.Summary.RightOnly != 40 {
		t.Fatalf("negative compatible scores lost their relative ordering: %#v", alignment.Summary)
	}
}

func TestAlignShapesCoordinatesTraceOneOfChoices(t *testing.T) {
	a := exactSpan("", "server", "unset", "GET a", "200")
	b := exactSpan("", "server", "unset", "GET b", "200")
	trace := func(roots ...SpanGroup) TraceGroup {
		return TraceGroup{Count: 1, ExactCount: true, MinCount: 1, MaxCount: 1, Roots: roots}
	}
	choice := TraceGroup{Cardinality: "one_of", MinCount: 1, MaxCount: 1, Alternatives: []TraceGroup{trace(a), trace(b)}}
	left := &ScenarioShape{Traces: []TraceGroup{choice, trace(a)}}
	right := &ScenarioShape{Traces: []TraceGroup{trace(a), trace(b)}}
	alignment := AlignShapes(left, right)
	if alignment.Summary.TraceMatched != 2 || alignment.Summary.TraceLeftOnly != 0 || alignment.Summary.TraceRightOnly != 0 {
		t.Fatalf("trace one-of choice was not coordinated: %#v", alignment.Summary)
	}
}

func TestAlignShapesChoosesWildcardAlternative(t *testing.T) {
	serverAny := exactSpan("", "server", "unset", "", "")
	clientA := exactSpan("", "client", "unset", "A", "")
	rightServer := exactSpan("", "server", "unset", "B", "")
	choice := SpanGroup{Cardinality: "one_of", MinCount: 1, MaxCount: 1, Alternatives: []SpanGroup{clientA, serverAny}}
	alignment := AlignShapes(shapeOf("left", choice), shapeOf("right", rightServer))
	if alignment.Summary.Matched != 1 || alignment.Summary.LeftOnly != 0 || alignment.Summary.RightOnly != 0 {
		t.Fatalf("wildcard alternative was not selected: %#v", alignment.Summary)
	}
}

func TestAlignShapesMatchesEquivalentRoutes(t *testing.T) {
	left := shapeOf("left", exactSpan("django", "server", "unset", "GET api/articles/<slug>", "200"))
	right := shapeOf("right", exactSpan("aiohttp", "server", "unset", "GET /api/articles/:slug", "200"))
	alignment := AlignShapes(left, right)
	if alignment.Summary.TraceMatched != 1 || alignment.Summary.Matched != 1 {
		t.Fatalf("unexpected summary %#v", alignment.Summary)
	}
	row := findRow(t, alignment, "GET api/articles/<slug>")
	if row.Kind != "matched" {
		t.Fatalf("expected matched row, got %q", row.Kind)
	}
	diffs := strings.Join(row.Diffs, ",")
	if !strings.Contains(diffs, "scope") || !strings.Contains(diffs, "name") {
		t.Fatalf("expected scope and name diffs, got %v", row.Diffs)
	}
	if strings.Contains(diffs, "count") || strings.Contains(diffs, "status") {
		t.Fatalf("unexpected structural diffs %v", row.Diffs)
	}
}

func TestAlignShapesReportsCountAndOnlySideDifferences(t *testing.T) {
	query := exactSpan("db", "client", "unset", "SELECT articles", "absent")
	left := shapeOf("left", exactSpan("server", "server", "unset", "GET /api/tags", "200",
		repeated(3, query),
		exactSpan("cache", "client", "unset", "GET cache", "absent")))
	right := shapeOf("right", exactSpan("server", "server", "unset", "GET /api/tags", "200",
		repeated(1, query),
		exactSpan("template", "internal", "unset", "render", "absent")))
	alignment := AlignShapes(left, right)
	if alignment.Summary.LeftOnly != 1 || alignment.Summary.RightOnly != 1 {
		t.Fatalf("unexpected one-sided counts %#v", alignment.Summary)
	}
	row := findRow(t, alignment, "SELECT articles")
	if row.Kind != "matched" || len(row.Diffs) != 1 || row.Diffs[0] != "count" {
		t.Fatalf("expected a count difference, got %#v", row)
	}
	if row.LeftCard != "×3" || row.RightCard != "" {
		t.Fatalf("unexpected cardinality labels %q / %q", row.LeftCard, row.RightCard)
	}
	if cache := findRow(t, alignment, "GET cache"); cache.Kind != "left_only" || cache.Right != nil {
		t.Fatalf("expected left-only cache span, got %#v", cache)
	}
	if render := findRow(t, alignment, "render"); render.Kind != "right_only" || render.Left != nil {
		t.Fatalf("expected right-only render span, got %#v", render)
	}
	if alignment.Summary.Differing != 1 {
		t.Fatalf("expected one differing span, got %d", alignment.Summary.Differing)
	}
}

func TestAlignShapesReportsUnmatchedTraces(t *testing.T) {
	left := shapeOf("left", exactSpan("server", "server", "unset", "GET /api/tags", "200"))
	right := shapeOf("right", exactSpan("server", "server", "unset", "POST /api/users", "201"))
	alignment := AlignShapes(left, right)
	if alignment.Summary.TraceMatched != 0 || alignment.Summary.TraceLeftOnly != 1 || alignment.Summary.TraceRightOnly != 1 {
		t.Fatalf("unexpected trace summary %#v", alignment.Summary)
	}
	if len(alignment.Traces) != 2 {
		t.Fatalf("expected two unmatched trace groups, got %d", len(alignment.Traces))
	}
}

func TestAlignShapesPicksBestOneOfAlternativeAndVariableCardinality(t *testing.T) {
	sqlite := exactSpan("sqlite", "client", "unset", "SELECT articles", "absent")
	postgres := exactSpan("postgres", "client", "unset", "SELECT users", "absent")
	choice := SpanGroup{Cardinality: "one_of", MinCount: 1, MaxCount: 1, Alternatives: []SpanGroup{postgres, sqlite}}
	variable := sqlite
	variable.ExactCount, variable.Count, variable.MinCount, variable.MaxCount, variable.Cardinality = false, 0, 1, 3, "between"
	left := shapeOf("left", exactSpan("server", "server", "unset", "GET /api/tags", "200", choice))
	right := shapeOf("right", exactSpan("server", "server", "unset", "GET /api/tags", "200", variable))
	alignment := AlignShapes(left, right)
	row := findRow(t, alignment, "SELECT articles")
	if row.Kind != "matched" {
		t.Fatalf("one-of alternative was not chosen to match: %#v", row)
	}
	if row.LeftCard != "one of 2" {
		t.Fatalf("expected one-of label, got %q", row.LeftCard)
	}
	if row.RightCard != "×1–3" {
		t.Fatalf("expected variable cardinality label, got %q", row.RightCard)
	}
}

func TestAlignShapesChoosesReorderedOneOfAlternativesDeterministically(t *testing.T) {
	article := exactSpan("db", "client", "unset", "SELECT articles", "absent")
	user := exactSpan("db", "client", "unset", "SELECT users", "absent")
	choice := func(alternatives ...SpanGroup) SpanGroup {
		return SpanGroup{Cardinality: "one_of", MinCount: 1, MaxCount: 1, Alternatives: alternatives}
	}
	left := shapeOf("left", exactSpan("server", "server", "unset", "GET /api/tags", "200", choice(user, article)))
	right := shapeOf("right", exactSpan("server", "server", "unset", "GET /api/tags", "200", choice(article, user)))
	alignment := AlignShapes(left, right)
	if alignment.Summary.LeftOnly != 0 || alignment.Summary.RightOnly != 0 {
		t.Fatalf("equivalent reordered alternatives did not align: %#v", alignment.Summary)
	}
	row := findRow(t, alignment, "SELECT articles")
	if row.Kind != "matched" || row.LeftCard != "one of 2" || row.RightCard != "one of 2" {
		t.Fatalf("unexpected chosen alternative: %#v", row)
	}

	trace := func(root SpanGroup) TraceGroup {
		return TraceGroup{Count: 1, MinCount: 1, MaxCount: 1, ExactCount: true, Coverage: "complete", Roots: []SpanGroup{root}}
	}
	left.Traces = []TraceGroup{{Cardinality: "one_of", MinCount: 1, MaxCount: 1, Alternatives: []TraceGroup{trace(user), trace(article)}}}
	right.Traces = []TraceGroup{{Cardinality: "one_of", MinCount: 1, MaxCount: 1, Alternatives: []TraceGroup{trace(article), trace(user)}}}
	alignment = AlignShapes(left, right)
	if alignment.Summary.TraceMatched != 1 || alignment.Summary.TraceLeftOnly != 0 || alignment.Summary.TraceRightOnly != 0 {
		t.Fatalf("equivalent reordered trace alternatives did not align: %#v", alignment.Summary)
	}
}

func TestAlignShapesTreatsOmittedMatchersAsWildcards(t *testing.T) {
	leftChild := exactSpan("", "client", "", "", "")
	left := shapeOf("left", exactSpan("", "", "", "GET /api/tags", "", leftChild))
	right := shapeOf("right", exactSpan("server", "server", "unset", "GET /api/tags", "200",
		exactSpan("db", "client", "unset", "SELECT articles", "absent")))
	alignment := AlignShapes(left, right)
	if alignment.Summary.TraceMatched != 1 || alignment.Summary.Matched != 2 || alignment.Summary.LeftOnly != 0 || alignment.Summary.RightOnly != 0 {
		t.Fatalf("omitted matchers were treated as literals: %#v", alignment.Summary)
	}
	if row := findRow(t, alignment, "SELECT articles"); row.Kind != "matched" || !strings.Contains(strings.Join(row.Diffs, ","), "name") {
		t.Fatalf("wildcard span was not paired with its concrete counterpart: %#v", row)
	}
}

func TestAlignShapesWorksWithoutExactCounts(t *testing.T) {
	left := shapeOf("left", exactSpan("server", "server", "unset", "GET /api/tags", "200"))
	right := shapeOf("right", exactSpan("server", "server", "unset", "GET /api/tags", "200"))
	left.ExactCounts, right.ExactCounts = false, false
	alignment := AlignShapes(left, right)
	if alignment == nil || alignment.Summary.Matched != 1 {
		t.Fatalf("alignment must not depend on exact counts: %#v", alignment)
	}
	if AlignShapes(nil, right) != nil {
		t.Fatal("alignment of a missing shape must be nil")
	}
}

func TestFormatInstrumentationVersionAndLabel(t *testing.T) {
	implementations := []string{"python-sdk-v1.44", "python-auto-v0.65b0", "django-v0.65b0"}
	if got := FormatInstrumentationVersion(implementations); got != "python-sdk 1.44 + python-auto 0.65b0 + django 0.65b0" {
		t.Fatalf("unexpected version string %q", got)
	}
	if got := FormatProfileLabel("python", "Django", implementations); got != "Python · Django · auto 0.65b0" {
		t.Fatalf("unexpected profile label %q", got)
	}
	if got := FormatInstrumentationVersion([]string{"custom-patch"}); got != "custom-patch" {
		t.Fatalf("unversioned binding should be kept verbatim, got %q", got)
	}
	if got := FormatProfileLabel("go", "Gin", []string{"go-compile-v1.1"}); got != "Go · Gin · compile 1.1" {
		t.Fatalf("unexpected go label %q", got)
	}
	if got := FormatInstrumentationVersion([]string{"python-auto-v0-65b0", "go-otelbuild-v1-1-0", "sdk-v1.2.3-beta"}); got != "python-auto 0.65b0 + go-otelbuild 1.1.0 + sdk 1.2.3-beta" {
		t.Fatalf("unexpected dashed version string %q", got)
	}
	if got := FormatProfileLabel("python", "Django", []string{"python-auto-v0-65b0"}); got != "Python · Django · auto 0.65b0" {
		t.Fatalf("unexpected dashed profile label %q", got)
	}
}

// TestAlignRealShapesFlagsDatabaseCountDifferences aligns the checked-in tags
// shapes so the algorithm is exercised against authored corpus data, not only
// hand-built fixtures.
func TestAlignRealShapesFlagsDatabaseCountDifferences(t *testing.T) {
	args := flag.Args()
	if len(args) < 14 {
		t.Skip("shape runfiles are supplied by Bazel")
	}
	runfile := func(path string) string {
		return filepath.Join(os.Getenv("TEST_SRCDIR"), os.Getenv("TEST_WORKSPACE"), path)
	}
	// Bazel supplies these among many other runfiles, so find each shape by the
	// path it must have rather than by position in the argument list.
	shapeArg := func(profile string) string {
		suffix := "realworld/shape/" + profile + "/tags.scm"
		for _, arg := range args {
			if strings.HasSuffix(arg, suffix) {
				return arg
			}
		}
		t.Fatalf("no tags shape runfile for %s", profile)
		return ""
	}
	load := func(profile string) *ScenarioShape {
		data, err := os.ReadFile(runfile(shapeArg(profile)))
		if err != nil {
			t.Fatal(err)
		}
		shape, err := ParseScenarioShape(profile, "tags", "https://example.test/"+profile, string(data))
		if err != nil {
			t.Fatal(err)
		}
		return &shape
	}
	django := load("python-django-auto-v0-65b0")
	aiohttp := load("python-aiohttp-auto-v0-65b0")
	alignment := AlignShapes(django, aiohttp)
	if alignment == nil || alignment.Summary.TraceMatched == 0 {
		t.Fatalf("django and aiohttp tags traces did not align: %#v", alignment)
	}
	tags, found := TraceMatch{}, false
	for _, trace := range alignment.Traces {
		if trace.Kind != "matched" || len(trace.Spans) == 0 || trace.Spans[0].Left == nil {
			continue
		}
		if strings.Contains(NormalizeSpanName(trace.Spans[0].Left.Name), "api/tags") {
			tags, found = trace, true
		}
	}
	if !found {
		t.Fatal("the tags root span was not aligned across the two Python profiles")
	}
	// The two profiles disagree below the root: Django reports bare sqlite3
	// statements while aiohttp reports SQLAlchemy statements qualified by the
	// database file, so those children align one-sided rather than by count.
	if tags.Spans[0].Diffs == nil {
		t.Fatal("expected the matched tags root spans to differ in scope and exact name")
	}
	oneSided := 0
	for _, row := range tags.Spans {
		if row.Kind != "matched" {
			oneSided++
		}
	}
	if oneSided == 0 {
		t.Fatal("expected database spans unique to one implementation inside the tags trace")
	}
	if alignment.Summary.TraceRightOnly == 0 {
		t.Fatal("expected aiohttp-only trace groups for its standalone sqlite3 traces")
	}
	if len(args) < 16 {
		return
	}
	gin, rails := load("go-gin-otelbuild-v1-1-0"), load("ruby-rails-auto-v0-1-0")
	cross := AlignShapes(gin, rails)
	if cross == nil || (cross.Summary.LeftOnly == 0 && cross.Summary.RightOnly == 0) {
		t.Fatalf("expected framework-specific spans between gin and rails: %#v", cross)
	}
}
