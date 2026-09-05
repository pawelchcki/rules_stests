package report

import (
	"bytes"
	"encoding/json"
	"flag"
	"os"
	"path/filepath"
	"reflect"
	"strings"
	"testing"
)

const profileTestRegistry = `{"features":[
  {"id":"traces.span.end","binding":"span/end"},
  {"id":"traces.tracerprovider.get-a-tracer","binding":"tracer/get"}
]}`

const profileTestShapes = `(define capture-shapes
  (list (capture-shape 'span/all-completed (lambda (capture) #t))
        (capture-shape 'trace/scope-associated (lambda (capture) #t))))`

const profileTestRules = `(define proof-rules
  '(("traces.span.end" (assertion span/all-completed) (evidence wire-sufficient))
    ("traces.tracerprovider.get-a-tracer" (assertion trace/scope-associated) (evidence requires-immutable-source))))`

const profileTestImplementation = `(define sdk-v1 '(sdk "1.2.3"))
(define tracer-source "https://github.com/open-telemetry/example/blob/0123456789abcdef0123456789abcdef01234567/tracer.go")`

const profileTestSource = `(define profile
  (realworld-profile
    (id 'test-profile)
    (display-name "Test profile")
    (language 'python)
    (framework "Test framework")
    (implementation (compose sdk-v1))
    (service-name "test-service")
    (signals 'traces)
    (all (observed span/end))
    (scenario 'errors_auth
      (corroborated (sources tracer-source) tracer/get))))`

func compileProfileFixture(profile, implementation, rules, shapes string) (NormalizedProfilePlan, error) {
	return CompileNormalizedProfile(profile, []string{implementation}, []byte(profileTestRegistry), []byte(rules), []byte(shapes), []string{"articles", "errors_auth"})
}

func TestCompileNormalizedProfileComposesAndScopesDeterministically(t *testing.T) {
	first, err := compileProfileFixture(profileTestSource, profileTestImplementation, profileTestRules, profileTestShapes)
	if err != nil {
		t.Fatal(err)
	}
	second, err := compileProfileFixture(profileTestSource, profileTestImplementation, profileTestRules, profileTestShapes)
	if err != nil {
		t.Fatal(err)
	}
	firstJSON, _ := json.MarshalIndent(first, "", "  ")
	secondJSON, _ := json.MarshalIndent(second, "", "  ")
	if !bytes.Equal(firstJSON, secondJSON) {
		t.Fatal("normalized profile plan is not deterministic")
	}
	if first.Profile != "test-profile" || first.DisplayName != "Test profile" || first.Language != "python" || first.Framework != "Test framework" || first.ServiceName != "test-service" || len(first.Implementations) != 1 || first.Implementations[0] != "sdk-v1" {
		t.Fatalf("composition metadata was not preserved: %#v", first)
	}
	if got := first.Sources["tracer-source"]; !strings.Contains(got, "/blob/0123456789abcdef0123456789abcdef01234567/") {
		t.Fatalf("immutable source anchor was not preserved: %q", got)
	}
	if len(first.Proofs) != 2 || first.Proofs[0].FeatureID != "traces.span.end" || first.Proofs[0].Basis != "observed" {
		t.Fatalf("proofs were not sorted and normalized: %#v", first.Proofs)
	}
	if got := first.Proofs[1]; len(got.Scenarios) != 1 || got.Scenarios[0] != "errors_auth" || got.Basis != "corroborated" || got.Assertion != "trace/scope-associated" {
		t.Fatalf("scenario-scoped proof was not preserved: %#v", got)
	}
}

func TestCompileNormalizedProfileRejectsInvalidPlans(t *testing.T) {
	tests := []struct {
		name                    string
		profile, implementation string
		rules, shapes           string
		want                    string
	}{
		{"duplicate claim", strings.Replace(profileTestSource, "(all (observed span/end))", "(all (observed span/end)) (all (observed span/end))", 1), profileTestImplementation, profileTestRules, profileTestShapes, "duplicate feature claim"},
		{"unknown feature", strings.Replace(profileTestSource, "span/end", "span/missing", 1), profileTestImplementation, profileTestRules, profileTestShapes, "unknown feature binding"},
		{"missing proof rule", profileTestSource, profileTestImplementation, strings.Replace(profileTestRules, `("traces.tracerprovider.get-a-tracer" (assertion trace/scope-associated) (evidence requires-immutable-source))`, "", 1), profileTestShapes, "has no proof rule"},
		{"unknown capture shape", profileTestSource, profileTestImplementation, strings.Replace(profileTestRules, "trace/scope-associated", "trace/unknown", 1), profileTestShapes, "unknown capture shape"},
		{"unknown scenario", strings.Replace(profileTestSource, "errors_auth", "not_a_workload", 1), profileTestImplementation, profileTestRules, profileTestShapes, "unknown scope"},
		{"source-required observed", strings.Replace(profileTestSource, "(corroborated (sources tracer-source) tracer/get)", "(observed tracer/get)", 1), profileTestImplementation, profileTestRules, profileTestShapes, "requires immutable source"},
		{"wire claim must be observed", strings.Replace(profileTestSource, "(observed span/end)", "(corroborated (sources tracer-source) span/end)", 1), profileTestImplementation, profileTestRules, profileTestShapes, "must use observed basis"},
		{"mutable source", profileTestSource, strings.Replace(profileTestImplementation, "/blob/0123456789abcdef0123456789abcdef01234567/", "/blob/main/", 1), profileTestRules, profileTestShapes, "mutable"},
		{"unknown implementation", strings.Replace(profileTestSource, "compose sdk-v1", "compose missing-sdk", 1), profileTestImplementation, profileTestRules, profileTestShapes, "unknown implementation binding"},
		{"invalid evidence policy", profileTestSource, profileTestImplementation, strings.Replace(profileTestRules, "wire-sufficient", "trust-me", 1), profileTestShapes, "invalid evidence policy"},
		{"duplicate implementation binding", profileTestSource, profileTestImplementation + "\n(define sdk-v1 '(duplicate))", profileTestRules, profileTestShapes, "duplicate implementation binding"},
		{"missing shape registry", profileTestSource, profileTestImplementation, profileTestRules, "(define other '())", "capture-shapes definition is missing"},
	}
	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			_, err := compileProfileFixture(test.profile, test.implementation, test.rules, test.shapes)
			if err == nil || !strings.Contains(err.Error(), test.want) {
				t.Fatalf("want error containing %q, got %v", test.want, err)
			}
		})
	}
}

func TestCheckedInProfilePlanSnapshotsAndDescriptorOwnership(t *testing.T) {
	args := flag.Args()
	if len(args) < 12 {
		t.Skip("profile plan runfiles are supplied by Bazel")
	}
	runfile := func(path string) string {
		return filepath.Join(os.Getenv("TEST_SRCDIR"), os.Getenv("TEST_WORKSPACE"), path)
	}
	type expectation struct {
		proofs, observed int
		implementations  []string
		// The source that must define this profile's descriptor composition:
		// its own specification, or the parts library it shares with the
		// variants of the same profile family.
		descriptorSource string
	}
	expectations := map[string]expectation{
		"go-gin-otelbuild-v1-1-0": {49, 22, []string{"go-compile-v1.1", "go-runtime-v0.70"},
			"corpus/realworld/profile/go-gin-otelbuild-v1-1-0.scm"},
		"python-aiohttp-auto-v0-65b0": {62, 26, []string{"python-sdk-v1.44", "python-auto-v0.65b0", "python-system-metrics-v0.65b0", "aiohttp-v0.65b0"},
			"corpus/realworld/profile/python-aiohttp-auto-v0-65b0.scm"},
		"python-django-auto-v0-65b0": {65, 27, []string{"python-sdk-v1.44", "python-auto-v0.65b0", "python-system-metrics-v0.65b0", "django-v0.65b0"},
			"corpus/realworld/profile/parts/python-django-auto-v0-65b0.scm"},
		"python-django-auto-v0-65b0-propagators-b3": {60, 26, []string{"python-sdk-v1.44", "python-auto-v0.65b0", "python-system-metrics-v0.65b0", "django-v0.65b0"},
			"corpus/realworld/profile/parts/python-django-auto-v0-65b0.scm"},
		"python-django-auto-v0-65b0-temporality-delta": {54, 24, []string{"python-sdk-v1.44", "python-auto-v0.65b0", "python-system-metrics-v0.65b0", "django-v0.65b0"},
			"corpus/realworld/profile/parts/python-django-auto-v0-65b0.scm"},
		"ruby-rails-auto-v0-1-0": {33, 17, []string{"ruby-sdk-v1.11", "ruby-auto-v0.1", "rules-stests-ruby-auto-patch-v1", "rails-v0.40", "rack-v0.30", "active-record-v0.13"},
			"corpus/realworld/profile/ruby-rails-auto-v0-1-0.scm"},
	}
	// Bazel passes the plans, then the specifications, then the neutral
	// contract, then the parts libraries, all in sorted profile order. Index the
	// plans by the profile each one names rather than by position, so adding a
	// variant cannot silently re-point an expectation at another profile.
	planCount := len(expectations)
	if len(args) < 3+2*planCount+1 {
		t.Fatalf("want at least %d runfile arguments, got %d", 3+2*planCount+1, len(args))
	}
	totalProofs, totalObserved, scopedExceptions := 0, 0, 0
	seen := map[string]bool{}
	for _, path := range args[3 : 3+planCount] {
		data, err := os.ReadFile(runfile(path))
		if err != nil {
			t.Fatal(err)
		}
		var plan NormalizedProfilePlan
		if err := json.Unmarshal(data, &plan); err != nil {
			t.Fatal(err)
		}
		expected, ok := expectations[plan.Profile]
		if !ok {
			t.Fatalf("plan %s names unregistered profile %q", path, plan.Profile)
		}
		if seen[plan.Profile] {
			t.Fatalf("profile %q has more than one plan", plan.Profile)
		}
		seen[plan.Profile] = true
		if len(plan.Proofs) != expected.proofs || !reflect.DeepEqual(plan.Implementations, expected.implementations) {
			t.Fatalf("normalized snapshot changed for %s: %#v", plan.Profile, plan)
		}
		observed := 0
		for _, proof := range plan.Proofs {
			if proof.Basis == "observed" {
				observed++
			}
			if strings.Contains(proof.FeatureID, "span-exceptions") {
				if plan.Profile != "python-django-auto-v0-65b0" || !reflect.DeepEqual(proof.Scenarios, []string{"errors_auth"}) {
					t.Fatalf("exception proof has wrong ownership or scope: %#v", proof)
				}
				scopedExceptions++
			}
		}
		if observed != expected.observed {
			t.Fatalf("%s has %d observed proofs, want %d", plan.Profile, observed, expected.observed)
		}
		for name, href := range plan.Sources {
			if err := validateImmutableSource(href); err != nil {
				t.Fatalf("%s source %s: %v", plan.Profile, name, err)
			}
		}
		totalProofs += len(plan.Proofs)
		totalObserved += observed
	}
	if len(seen) != planCount {
		t.Fatalf("saw %d plans, want %d", len(seen), planCount)
	}
	if totalProofs != 323 || totalObserved != 142 || scopedExceptions != 2 {
		t.Fatalf("claim snapshot changed: proofs=%d observed=%d scoped-exceptions=%d", totalProofs, totalObserved, scopedExceptions)
	}

	owners := map[string]bool{}
	for _, expected := range expectations {
		owners[expected.descriptorSource] = true
	}
	for path := range owners {
		source, err := os.ReadFile(runfile(path))
		if err != nil {
			t.Fatal(err)
		}
		if !bytes.Contains(source, []byte("(define expected-metric-descriptors")) {
			t.Fatalf("%s does not own its descriptor composition", path)
		}
	}
	contract, err := os.ReadFile(runfile(args[3+2*planCount]))
	if err != nil {
		t.Fatal(err)
	}
	if bytes.Contains(contract, []byte("expected-metric-descriptors")) {
		t.Fatal("language-neutral RealWorld contract owns implementation descriptors")
	}
}
