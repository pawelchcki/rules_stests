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
	Evidence  []Evidence `json:"evidence"`
}

type Manifest struct {
	SchemaVersion          int            `json:"schemaVersion"`
	Profile                string         `json:"profile"`
	DisplayName            string         `json:"displayName"`
	Language               string         `json:"language"`
	Framework              string         `json:"framework"`
	InstrumentationVersion string         `json:"instrumentationVersion"`
	ProfileEvidence        []Evidence     `json:"profileEvidence"`
	BaseCoverage           string         `json:"baseCoverage"`
	DefaultVerification    string         `json:"defaultVerification"`
	Verifications          []Verification `json:"verifications"`
}

type Golden struct {
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
	LeftProfile  string         `json:"leftProfile"`
	RightProfile string         `json:"rightProfile"`
	Scenario     string         `json:"scenario"`
	Available    bool           `json:"available"`
	TraceDelta   int            `json:"traceDelta"`
	SpanDelta    int            `json:"spanDelta"`
	ScopeDelta   map[string]int `json:"scopeDelta"`
	StatusDelta  map[string]int `json:"statusDelta"`
	CountDelta   int            `json:"countDelta"`
	Left         *Golden        `json:"left,omitempty"`
	Right        *Golden        `json:"right,omitempty"`
}

type ReportModel struct {
	GeneratedFrom string                             `json:"generatedFrom"`
	Metadata      CatalogMetadata                    `json:"metadata"`
	Features      []Feature                          `json:"features"`
	Manifests     []Manifest                         `json:"manifests"`
	Verification  map[string]map[string]Verification `json:"verification"`
	Scenarios     []string                           `json:"scenarios"`
	Coverage      []CoverageCell                     `json:"coverage"`
	Goldens       []Golden                           `json:"goldens"`
	Comparisons   []Comparison                       `json:"comparisons"`
}
