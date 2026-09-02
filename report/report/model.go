package report

type CatalogMetadata struct {
	SchemaVersion  int                       `json:"schemaVersion"`
	Source         CatalogSource             `json:"source"`
	MaturitySource string                    `json:"maturitySource"`
	Maturity       map[string]SignalMaturity `json:"maturity"`
}

type CatalogSource struct {
	Revision string `json:"revision"`
	URL      string `json:"url"`
	RawURL   string `json:"rawUrl"`
	SHA256   string `json:"sha256"`
}

type SignalMaturity struct {
	Traces  string `json:"traces"`
	Metrics string `json:"metrics"`
	Logs    string `json:"logs"`
}

type Feature struct {
	ID       string            `json:"id"`
	Category string            `json:"category"`
	Group    string            `json:"group,omitempty"`
	Name     string            `json:"name"`
	Optional string            `json:"optional,omitempty"`
	Support  map[string]string `json:"support"`
	Source   string            `json:"source"`
}

type Evidence struct {
	Label string `json:"label"`
	Href  string `json:"href"`
	Path  string `json:"path,omitempty"`
}

type Verification struct {
	FeatureID string     `json:"featureId"`
	State     string     `json:"state"`
	Basis     string     `json:"basis,omitempty"`
	Assertion string     `json:"assertion,omitempty"`
	Scenarios []string   `json:"scenarios,omitempty"`
	Evidence  []Evidence `json:"evidence"`
}

type FeatureClaim struct {
	FeatureID    string
	Basis        string
	Assertion    string
	AllScenarios bool
	Scenarios    []string
	Evidence     []Evidence
}

type ProfileProofCoverage struct {
	Profile string
	Source  Evidence
	Claims  []FeatureClaim
}

type ProofPlanProof struct {
	FeatureID      string   `json:"featureId"`
	Assertion      string   `json:"assertion"`
	Basis          string   `json:"basis"`
	EvidencePolicy string   `json:"evidencePolicy"`
	Scenarios      []string `json:"scenarios,omitempty"`
	Sources        []string `json:"sources,omitempty"`
}

type NormalizedProfilePlan struct {
	SchemaVersion   int               `json:"schemaVersion"`
	Profile         string            `json:"profile"`
	DisplayName     string            `json:"displayName"`
	Language        string            `json:"language"`
	Framework       string            `json:"framework"`
	ServiceName     string            `json:"serviceName"`
	Signals         []string          `json:"signals"`
	Implementations []string          `json:"implementations"`
	Sources         map[string]string `json:"sources"`
	Proofs          []ProofPlanProof  `json:"proofs"`
}

type Manifest struct {
	SchemaVersion          int    `json:"schemaVersion"`
	Profile                string `json:"profile"`
	DisplayName            string `json:"displayName"`
	Language               string `json:"language"`
	Framework              string `json:"framework"`
	InstrumentationVersion string `json:"instrumentationVersion"`
	Version                string `json:"version,omitempty"`
	ShortLabel             string `json:"shortLabel,omitempty"`
	// Unexercised marks a profile that is declared in the corpus but produced
	// no receipts in this build, usually because its container images are not
	// published. Its corpus data is shown; none of its features can be
	// verified.
	Unexercised         bool           `json:"unexercised,omitempty"`
	ProfileEvidence     []Evidence     `json:"profileEvidence"`
	BaseCoverage        string         `json:"baseCoverage"`
	DefaultVerification string         `json:"defaultVerification"`
	Verifications       []Verification `json:"verifications"`
}

type ScenarioShape struct {
	Profile     string         `json:"profile"`
	Scenario    string         `json:"scenario"`
	Source      string         `json:"source"`
	Traces      []TraceGroup   `json:"traces"`
	ExactCounts bool           `json:"exactCounts"`
	TraceCount  int            `json:"traceCount"`
	SpanCount   int            `json:"spanCount"`
	Scopes      map[string]int `json:"scopes"`
	Statuses    map[string]int `json:"statuses"`
}

type TraceGroup struct {
	Count        int          `json:"count"`
	ExactCount   bool         `json:"exactCount"`
	MinCount     int          `json:"minCount,omitempty"`
	MaxCount     int          `json:"maxCount,omitempty"`
	Cardinality  string       `json:"cardinality,omitempty"`
	Alternatives []TraceGroup `json:"alternatives,omitempty"`
	Coverage     string       `json:"coverage,omitempty"`
	Roots        []SpanGroup  `json:"roots,omitempty"`
}

type SpanGroup struct {
	Count        int         `json:"count"`
	ExactCount   bool        `json:"exactCount"`
	MinCount     int         `json:"minCount,omitempty"`
	MaxCount     int         `json:"maxCount,omitempty"`
	Cardinality  string      `json:"cardinality,omitempty"`
	Alternatives []SpanGroup `json:"alternatives,omitempty"`
	Span         SpanNode    `json:"span,omitempty"`
}

type SpanNode struct {
	Scope      string      `json:"scope"`
	Kind       string      `json:"kind"`
	Status     string      `json:"status"`
	Name       string      `json:"name"`
	HTTPStatus string      `json:"httpStatus"`
	Children   []SpanGroup `json:"children,omitempty"`
}

type CoverageCell struct {
	Profile  string `json:"profile"`
	Scenario string `json:"scenario"`
	State    string `json:"state"`
}

type Comparison struct {
	LeftProfile  string          `json:"leftProfile"`
	RightProfile string          `json:"rightProfile"`
	Scenario     string          `json:"scenario"`
	Available    bool            `json:"available"`
	TraceDelta   int             `json:"traceDelta"`
	SpanDelta    int             `json:"spanDelta"`
	ScopeDelta   map[string]int  `json:"scopeDelta"`
	StatusDelta  map[string]int  `json:"statusDelta"`
	CountDelta   int             `json:"countDelta"`
	Left         *ScenarioShape  `json:"left,omitempty"`
	Right        *ScenarioShape  `json:"right,omitempty"`
	Alignment    *ShapeAlignment `json:"alignment,omitempty"`
}

// ShapeAlignment is the span-by-span pairing of two scenario shapes.
type ShapeAlignment struct {
	Traces  []TraceMatch `json:"traces"`
	Summary AlignSummary `json:"summary"`
}

type AlignSummary struct {
	TraceMatched   int `json:"traceMatched"`
	TraceLeftOnly  int `json:"traceLeftOnly"`
	TraceRightOnly int `json:"traceRightOnly"`
	// Span totals count authored span groups (the rendered rows), not expanded
	// cardinalities. Each row carries its own exact or ranged count label.
	Matched   int `json:"matched"`
	LeftOnly  int `json:"leftOnly"`
	RightOnly int `json:"rightOnly"`
	Differing int `json:"differing"`
}

type TraceRef struct {
	Index int    `json:"index"`
	Label string `json:"label"`
	Card  string `json:"card,omitempty"`
}

type TraceMatch struct {
	Kind  string      `json:"kind"`
	Left  *TraceRef   `json:"left,omitempty"`
	Right *TraceRef   `json:"right,omitempty"`
	Spans []SpanMatch `json:"spans"`
}

type SpanMatch struct {
	Kind      string    `json:"kind"`
	Depth     int       `json:"depth"`
	Left      *SpanNode `json:"left,omitempty"`
	Right     *SpanNode `json:"right,omitempty"`
	LeftCard  string    `json:"leftCard,omitempty"`
	RightCard string    `json:"rightCard,omitempty"`
	Diffs     []string  `json:"diffs,omitempty"`
}

type ReportModel struct {
	GeneratedFrom string                             `json:"generatedFrom"`
	Metadata      CatalogMetadata                    `json:"metadata"`
	Features      []Feature                          `json:"features"`
	Manifests     []Manifest                         `json:"manifests"`
	Verification  map[string]map[string]Verification `json:"verification"`
	Scenarios     []string                           `json:"scenarios"`
	Coverage      []CoverageCell                     `json:"coverage"`
	Shapes        []ScenarioShape                    `json:"shapes"`
	Receipts      []ValidationReceipt                `json:"receipts,omitempty"`
	Comparisons   []Comparison                       `json:"comparisons"`
}
