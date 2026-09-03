package report

import (
	"flag"
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

func TestNormalizeSpanNameCollapsesRouteParameters(t *testing.T) {
	tests := map[string]string{
		"GET /api/articles/<slug>":  "get api/articles/*",
		"GET /api/articles/:slug":   "get api/articles/*",
		"GET /api/articles/{slug}":  "get api/articles/*",
		"GET /api/articles/%{slug}": "get api/articles/*",
		"GET   /api/tags":           "get api/tags",
		"SELECT  …  articles_tag":   "select … articles_tag",
		"SELECT value::text":        "select value::text",
		"SELECT value::integer":     "select value::integer",
	}
	for input, want := range tests {
		if got := NormalizeSpanName(input); got != want {
			t.Errorf("NormalizeSpanName(%q) = %q, want %q", input, got, want)
		}
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
	left := shapeOf("left", exactSpan("django", "server", "unset", "GET /api/articles/<slug>", "200"))
	right := shapeOf("right", exactSpan("aiohttp", "server", "unset", "GET /api/articles/:slug", "200"))
	alignment := AlignShapes(left, right)
	if alignment.Summary.TraceMatched != 1 || alignment.Summary.Matched != 1 {
		t.Fatalf("unexpected summary %#v", alignment.Summary)
	}
	row := findRow(t, alignment, "GET /api/articles/<slug>")
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
	load := func(profile, path string) *ScenarioShape {
		data, err := os.ReadFile(runfile(path))
		if err != nil {
			t.Fatal(err)
		}
		shape, err := ParseScenarioShape(profile, "tags", "https://example.test/"+profile, string(data))
		if err != nil {
			t.Fatal(err)
		}
		return &shape
	}
	django := load("python-django-auto-v0-65b0", args[12])
	aiohttp := load("python-aiohttp-auto-v0-65b0", args[13])
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
	gin, rails := load("go-gin-otelbuild-v1-1-0", args[14]), load("ruby-rails-auto-v0-1-0", args[15])
	cross := AlignShapes(gin, rails)
	if cross == nil || (cross.Summary.LeftOnly == 0 && cross.Summary.RightOnly == 0) {
		t.Fatalf("expected framework-specific spans between gin and rails: %#v", cross)
	}
}
