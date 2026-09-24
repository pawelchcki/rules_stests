package main

import (
	"bytes"
	"crypto/sha256"
	"encoding/json"
	"flag"
	"fmt"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"regexp"
	"strconv"
	"strings"
	"time"

	"github.com/pawelchcki/rules_stests/report"
)

type labObject = map[string]any

type labProofEvidence struct {
	SchemaVersion  int      `json:"schemaVersion"`
	Language       string   `json:"language"`
	Scenario       string   `json:"scenario"`
	CaptureSHA256  string   `json:"captureSha256"`
	SourceSHA256   string   `json:"sourceSha256"`
	ResponseSHA256 string   `json:"responseSha256"`
	FeatureIDs     []string `json:"featureIds"`
}

var labRevisionPattern = regexp.MustCompile(`^[0-9a-f]{40}$`)

func labPlanProofs(data []byte, language, scenario string) ([]report.ReceiptProof, error) {
	var plan report.NormalizedProfilePlan
	decoder := json.NewDecoder(bytes.NewReader(data))
	decoder.DisallowUnknownFields()
	if err := decoder.Decode(&plan); err != nil {
		return nil, err
	}
	if plan.SchemaVersion != 1 || plan.Profile != language+"-telemetry-lab" || plan.Language != language {
		return nil, fmt.Errorf("lab plan identity mismatch for %s", language)
	}
	claims := labClaims[language]
	if scenario != "base" {
		claims = labVariantClaims[scenario]
	}
	wanted := make(map[string]bool, len(claims))
	for _, id := range claims {
		wanted[id] = true
	}
	proofs := make([]report.ReceiptProof, 0, len(claims))
	for _, proof := range plan.Proofs {
		if len(proof.Scenarios) != 1 || proof.Scenarios[0] != scenario {
			continue
		}
		if !wanted[proof.FeatureID] || proof.Assertion != "telemetry-lab/"+proof.FeatureID || proof.Basis != "observed" {
			return nil, fmt.Errorf("unexpected lab plan proof %s in %s", proof.FeatureID, scenario)
		}
		proofs = append(proofs, report.ReceiptProof{FeatureID: proof.FeatureID, Assertion: proof.Assertion, Basis: proof.Basis, Result: "pass"})
		delete(wanted, proof.FeatureID)
	}
	if len(wanted) != 0 || len(proofs) != len(claims) {
		return nil, fmt.Errorf("lab plan does not cover all %s claims for %s", language, scenario)
	}
	return proofs, nil
}

func labAcceptedCapture(capture, responses []byte) ([]byte, error) {
	var records []json.RawMessage
	if err := json.Unmarshal(capture, &records); err != nil {
		return nil, err
	}
	if len(records) == 0 {
		return nil, fmt.Errorf("lab receipt needs captured telemetry")
	}
	var first map[string]json.RawMessage
	if err := json.Unmarshal(records[0], &first); err != nil {
		return nil, err
	}
	if _, exists := first["labResponses"]; exists {
		return nil, fmt.Errorf("capture already has labResponses")
	}
	first["labResponses"] = json.RawMessage(responses)
	encodedFirst, err := json.Marshal(first)
	if err != nil {
		return nil, err
	}
	records[0] = encodedFirst
	encoded, err := json.MarshalIndent(records, "", "  ")
	if err != nil {
		return nil, err
	}
	return append(encoded, '\n'), nil
}

func labWriteReceipt(root, language, scenario string, plan, capture, responses []byte, proofs []report.ReceiptProof) error {
	revision := os.Getenv("OTEL_TEST_REVISION")
	if revision == "" {
		return nil
	}
	if !labRevisionPattern.MatchString(revision) {
		return fmt.Errorf("OTEL_TEST_REVISION must be a lowercase 40-character commit")
	}
	if root == "" {
		return fmt.Errorf("TEST_UNDECLARED_OUTPUTS_DIR is unavailable for lab receipt")
	}
	accepted, err := labAcceptedCapture(capture, responses)
	if err != nil {
		return err
	}
	receipt := report.ValidationReceipt{
		SchemaVersion: 1, Revision: revision, Profile: language + "-telemetry-lab", Scenario: scenario,
		ProofPlanSHA256: fmt.Sprintf("%x", sha256.Sum256(plan)), CaptureSHA256: fmt.Sprintf("%x", sha256.Sum256(accepted)),
		ValidationMode: "contract", Outcome: "verified", Proofs: proofs,
	}
	encoded, err := json.MarshalIndent(receipt, "", "  ")
	if err != nil {
		return err
	}
	encoded = append(encoded, '\n')
	if _, err := report.DecodeReceipt(encoded); err != nil {
		return err
	}
	directory := filepath.Join(root, "receipts", receipt.Profile)
	if err := os.MkdirAll(directory, 0o755); err != nil {
		return err
	}
	if err := os.WriteFile(filepath.Join(directory, scenario+".capture.json"), accepted, 0o644); err != nil {
		return err
	}
	return os.WriteFile(filepath.Join(directory, scenario+".json"), encoded, 0o644)
}

func labSource(value string) ([]byte, error) {
	candidates := []string{value}
	if runfiles := os.Getenv("RUNFILES_DIR"); runfiles != "" {
		candidates = append(candidates, filepath.Join(runfiles, value))
	}
	if testSrcdir := os.Getenv("TEST_SRCDIR"); testSrcdir != "" {
		candidates = append(candidates, filepath.Join(testSrcdir, value))
	}
	for _, path := range candidates {
		if data, err := os.ReadFile(path); err == nil {
			return data, nil
		}
	}
	return nil, fmt.Errorf("source %q is absent from runfiles", value)
}

func labField(value labObject, key string) any {
	key = strings.ToLower(strings.ReplaceAll(key, "_", ""))
	for name, child := range value {
		if strings.ToLower(strings.ReplaceAll(name, "_", "")) == key {
			return child
		}
	}
	return nil
}

func labObjects(value any, key string) []labObject {
	var found []labObject
	var walk func(any)
	walk = func(value any) {
		switch item := value.(type) {
		case map[string]any:
			for name, child := range item {
				if strings.EqualFold(strings.ReplaceAll(name, "_", ""), strings.ReplaceAll(key, "_", "")) {
					if array, ok := child.([]any); ok {
						for _, element := range array {
							if object, ok := element.(map[string]any); ok {
								found = append(found, object)
							}
						}
					}
				} else {
					walk(child)
				}
			}
		case []any:
			for _, child := range item {
				walk(child)
			}
		}
	}
	walk(value)
	return found
}

func labPort(suffix string) (int, error) {
	var assigned map[string]json.RawMessage
	if err := json.Unmarshal([]byte(os.Getenv("ASSIGNED_PORTS")), &assigned); err != nil {
		return 0, fmt.Errorf("decode ASSIGNED_PORTS: %w", err)
	}
	for label, raw := range assigned {
		if !strings.HasSuffix(label, suffix) {
			continue
		}
		var port int
		if err := json.Unmarshal(raw, &port); err == nil {
			return port, nil
		}
		var text string
		if err := json.Unmarshal(raw, &text); err == nil {
			return strconv.Atoi(text)
		}
	}
	return 0, fmt.Errorf("service %q absent from ASSIGNED_PORTS", suffix)
}

func labRequest(client *http.Client, method, endpoint string) ([]byte, error) {
	request, err := http.NewRequest(method, endpoint, nil)
	if err != nil {
		return nil, err
	}
	if strings.HasSuffix(endpoint, "/v1/propagation") {
		request.Header.Set("traceparent", "00-0123456789abcdef0123456789abcdef-0123456789abcdef-01")
		request.Header.Set("baggage", "incoming=value")
	}
	response, err := client.Do(request)
	if err != nil {
		return nil, err
	}
	defer response.Body.Close()
	data, err := io.ReadAll(response.Body)
	if err != nil {
		return nil, err
	}
	if response.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("%s returned %d: %s", endpoint, response.StatusCode, data)
	}
	return data, nil
}

func labNamed(values []labObject, name string) labObject {
	for _, item := range values {
		if labField(item, "name") == name {
			return item
		}
	}
	return nil
}

func labAttribute(item labObject, key string) labObject {
	array, _ := labField(item, "attributes").([]any)
	for _, element := range array {
		attribute, ok := element.(map[string]any)
		if ok && labField(attribute, "key") == key {
			value, _ := labField(attribute, "value").(map[string]any)
			if nested, ok := labField(value, "value").(map[string]any); ok {
				return nested
			}
			return value
		}
	}
	return nil
}

func labVerify(data []byte, language, scenario string) error {
	var records []any
	decoder := json.NewDecoder(bytes.NewReader(data))
	decoder.UseNumber()
	if err := decoder.Decode(&records); err != nil {
		return err
	}
	spans := labObjects(records, "spans")
	parent := labNamed(spans, "lab.parent")
	child := labNamed(spans, "lab.child.renamed")
	exception := labNamed(spans, "lab.exception")
	if parent == nil || child == nil || exception == nil {
		return fmt.Errorf("missing lab spans: parent=%t child=%t exception=%t", parent != nil, child != nil, exception != nil)
	}
	if labField(parent, "trace_id") != labField(child, "trace_id") || labField(child, "parent_span_id") != labField(parent, "span_id") {
		return fmt.Errorf("lab child is not parented to lab parent")
	}
	for key, kind := range map[string]string{"lab.string": "string_value", "lab.boolean": "bool_value", "lab.integer": "int_value", "lab.double": "double_value", "lab.array": "array_value"} {
		if language == "python" && scenario == "attribute-count" && key == "lab.string" {
			continue
		}
		if labField(labAttribute(parent, key), kind) == nil {
			return fmt.Errorf("parent lacks %s of kind %s", key, kind)
		}
	}
	wantUpdated := "after-start"
	if language == "python" && (scenario == "span-value-length" || scenario == "attribute-value-length") {
		wantUpdated = "aft"
	}
	if labField(labAttribute(child, "lab.updated"), "string_value") != wantUpdated {
		return fmt.Errorf("child attribute set after start was lost")
	}
	events, _ := labField(parent, "events").([]any)
	wantEvents := []string{"lab.first", "lab.second"}
	if language == "python" && scenario == "span-events" {
		wantEvents = []string{"lab.second"}
		if dropped, ok := labUint(labField(parent, "dropped_events_count")); !ok || dropped != 1 {
			return fmt.Errorf("Python span event limit did not report one dropped event")
		}
	}
	if len(events) != len(wantEvents) {
		return fmt.Errorf("parent event count = %d, want %d", len(events), len(wantEvents))
	}
	for index, name := range wantEvents {
		event, ok := events[index].(map[string]any)
		if !ok || labField(event, "name") != name {
			return fmt.Errorf("parent event %d is not %s", index, name)
		}
	}
	if language == "python" && scenario == "event-attributes" {
		first, _ := events[0].(map[string]any)
		attributes, _ := labField(first, "attributes").([]any)
		dropped, ok := labUint(labField(first, "dropped_attributes_count"))
		if len(attributes) != 1 || !ok || dropped != 1 {
			return fmt.Errorf("Python event attribute limit was not applied")
		}
	}
	exceptionEvents, _ := labField(exception, "events").([]any)
	foundException := false
	for _, element := range exceptionEvents {
		event, ok := element.(map[string]any)
		if ok && labField(event, "name") == "exception" {
			foundException = true
		}
	}
	if !foundException {
		return fmt.Errorf("record_exception exported no exception event")
	}
	status, _ := labField(exception, "status").(map[string]any)
	if status == nil || labField(status, "code") == nil {
		return fmt.Errorf("exception span has no status")
	}
	if language == "go" {
		shared := labNamed(spans, "lab.shared")
		if shared == nil {
			return fmt.Errorf("Go shared span is absent")
		}
		attributes, _ := labField(shared, "attributes").([]any)
		events, _ := labField(shared, "events").([]any)
		if len(attributes) != 32 || len(events) != 32 {
			return fmt.Errorf("concurrent Go span updates lost data: %d attributes, %d events", len(attributes), len(events))
		}
		workers := 0
		identities := map[string]bool{}
		for _, span := range spans {
			if labField(span, "name") != "lab.concurrent" {
				continue
			}
			if labField(span, "parent_span_id") != labField(shared, "span_id") || labField(span, "trace_id") != labField(shared, "trace_id") {
				return fmt.Errorf("Go concurrent worker lost shared parent")
			}
			id := fmt.Sprint(labField(span, "span_id"))
			if identities[id] {
				return fmt.Errorf("Go concurrent worker reused span ID %s", id)
			}
			identities[id] = true
			workers++
		}
		if workers != 32 {
			return fmt.Errorf("Go concurrent worker spans = %d, want 32", workers)
		}
	}
	if language == "python" {
		if scenario == "resource-attributes" {
			found := false
			for _, resourceSpans := range labObjects(records, "resource_spans") {
				resource, _ := labField(resourceSpans, "resource").(map[string]any)
				if labField(labAttribute(resource, "lab.resource"), "string_value") == "present" {
					found = true
				}
			}
			if !found {
				return fmt.Errorf("Python resource environment attribute is absent from exported spans")
			}
		}
		if scenario == "span-value-length" || scenario == "attribute-value-length" {
			if labField(labAttribute(parent, "lab.string"), "string_value") != "vis" {
				return fmt.Errorf("Python span attribute value length was not limited")
			}
		}
		if scenario == "attribute-count" {
			attrs, _ := labField(parent, "attributes").([]any)
			dropped, ok := labUint(labField(parent, "dropped_attributes_count"))
			if len(attrs) != 4 || !ok || dropped != 1 {
				return fmt.Errorf("Python span attribute limit was not applied: %d attributes, %d dropped", len(attrs), dropped)
			}
		}
		manual := labNamed(spans, "lab.manually-active")
		if manual == nil || labField(manual, "parent_span_id") != labField(parent, "span_id") {
			return fmt.Errorf("explicitly activated Python span did not inherit the current span")
		}
		links, _ := labField(parent, "links").([]any)
		wantedLinks := 3
		wantedIDs := []string{"123456789abcdef0", "123456789abcdef1", "123456789abcdef0"}
		if scenario == "links-count" {
			wantedLinks = 2
			wantedIDs = wantedIDs[1:]
			if dropped, ok := labUint(labField(parent, "dropped_links_count")); !ok || dropped != 1 {
				return fmt.Errorf("Python link limit did not report one dropped link")
			}
		}
		if len(links) != wantedLinks {
			return fmt.Errorf("Python parent link count = %d, want %d", len(links), wantedLinks)
		}
		for index, spanID := range wantedIDs {
			link, ok := links[index].(map[string]any)
			if !ok || labField(link, "span_id") != spanID {
				return fmt.Errorf("Python link %d was not preserved in order", index)
			}
			if scenario == "link-attributes" {
				attributes, _ := labField(link, "attributes").([]any)
				if len(attributes) != 1 {
					return fmt.Errorf("Python link %d retained %d attributes under limit 1", index, len(attributes))
				}
				if dropped, ok := labUint(labField(link, "dropped_attributes_count")); !ok || dropped != 1 {
					return fmt.Errorf("Python link %d did not report one dropped attribute", index)
				}
			}
		}
		lifecycle := labNamed(spans, "lab.lifecycle")
		if lifecycle == nil {
			return fmt.Errorf("Python lifecycle span is absent")
		}
		start, startOK := labUint(labField(lifecycle, "start_time_unix_nano"))
		end, endOK := labUint(labField(lifecycle, "end_time_unix_nano"))
		if !startOK || !endOK || end-start != 50_000_000 {
			return fmt.Errorf("explicit Python span timestamps not preserved: %d %d", start, end)
		}
		metrics := labObjects(records, "metrics")
		for _, name := range []string{"lab.requests", "lab.active", "lab.duration"} {
			if labNamed(metrics, name) == nil {
				return fmt.Errorf("missing Python metric %s", name)
			}
		}
		correlatedLog := false
		for _, record := range labObjects(records, "log_records") {
			body, _ := labField(record, "body").(map[string]any)
			value, _ := labField(body, "value").(map[string]any)
			if labField(value, "string_value") == "lab span request" && labField(record, "trace_id") == labField(parent, "trace_id") && labField(record, "span_id") == labField(parent, "span_id") {
				correlatedLog = true
			}
		}
		if !correlatedLog {
			return fmt.Errorf("Python log did not carry its active span context")
		}
	}
	return nil
}

func labUint(value any) (uint64, bool) {
	switch typed := value.(type) {
	case string:
		result, err := strconv.ParseUint(typed, 10, 64)
		return result, err == nil
	case float64:
		return uint64(typed), typed >= 0
	case json.Number:
		result, err := strconv.ParseUint(string(typed), 10, 64)
		return result, err == nil
	}
	return 0, false
}

func labMetricStream(response labObject, field, scope, name string) labObject {
	streams, _ := labField(response, field).([]any)
	for _, value := range streams {
		stream, ok := value.(map[string]any)
		if ok && labField(stream, "scope") == scope && labField(stream, "name") == name {
			return stream
		}
	}
	return nil
}

func labVerifyMetricViews(response labObject) error {
	if labField(response, "global") != true || labField(response, "providers_distinct") != true {
		return fmt.Errorf("Go global or multiple meter-provider operation failed")
	}
	streams, _ := labField(response, "streams").([]any)
	allStreams, _ := labField(response, "all_streams").([]any)
	if len(streams) != 6 || len(allStreams) != 1 {
		return fmt.Errorf("view stream count is %d/%d, want 6/1", len(streams), len(allStreams))
	}
	exact := labMetricStream(response, "streams", "lab.primary", "lab.view.renamed")
	wildcard := labMetricStream(response, "streams", "lab.primary", "lab.view.counter")
	unmatched := labMetricStream(response, "streams", "lab.primary", "lab.unmatched")
	firstScope := labMetricStream(response, "streams", "lab.primary", "lab.scope.counter")
	secondScope := labMetricStream(response, "streams", "lab.secondary", "lab.scope.counter")
	concurrent := labMetricStream(response, "streams", "lab.concurrent", "lab.concurrent.counter")
	matchAll := labMetricStream(response, "all_streams", "lab.all", "lab.all.counter")
	if exact == nil || wildcard == nil || unmatched == nil || firstScope == nil || secondScope == nil || concurrent == nil || matchAll == nil {
		return fmt.Errorf("required exact, wildcard, scoped, concurrent, or match-all metric stream is absent")
	}
	exactAttrs, _ := labField(exact, "attributes").(map[string]any)
	wildAttrs, _ := labField(wildcard, "attributes").(map[string]any)
	if labField(exact, "description") != "renamed by exact view" || labField(exact, "unit") != "{call}" || labField(exact, "value") != float64(3) || len(exactAttrs) != 1 || labField(exactAttrs, "lab.keep") != "yes" {
		return fmt.Errorf("exact view did not apply name, description, unit, attributes, and sum")
	}
	if labField(wildcard, "description") != "selected by wildcard" || labField(wildcard, "value") != float64(3) || len(wildAttrs) != 1 || labField(wildAttrs, "lab.keep") != "yes" {
		return fmt.Errorf("wildcard view did not filter excluded attribute")
	}
	if labField(unmatched, "value") != float64(4) || labField(firstScope, "value") != float64(6) || labField(secondScope, "value") != float64(7) || labField(concurrent, "value") != float64(32) || labField(matchAll, "description") != "matched all" || labField(matchAll, "value") != float64(8) {
		return fmt.Errorf("unmatched, scoped, concurrent, or match-all metrics differ")
	}
	for _, item := range streams {
		stream, _ := item.(map[string]any)
		if labField(stream, "name") == "lab.dropped" {
			return fmt.Errorf("drop aggregation exported a metric stream")
		}
	}
	return nil
}

func labVerifyMetricAdvanced(response labObject) error {
	if labField(response, "scope_attributes") != true || labField(response, "duplicate_value") != float64(5) || labField(response, "default_counter_sum") != true {
		return fmt.Errorf("advanced meter scope or duplicate/default counter mismatch: %v", response)
	}
	bounds, _ := labField(response, "advisory_bounds").([]any)
	if len(bounds) != 2 || bounds[0] != float64(2) || bounds[1] != float64(4) || labField(response, "exponential") != true {
		return fmt.Errorf("advisory boundaries or exponential histogram mismatch: %v", response)
	}
	points, _ := labField(response, "cardinal_points").(float64)
	if points < 1 || points > 2 || labField(response, "cardinal_total") != float64(4) {
		return fmt.Errorf("cardinality limit dropped measurements: %v", response)
	}
	if labField(response, "invalid_scope") == nil {
		return fmt.Errorf("invalid meter failed to create a working instrument: %v", response)
	}
	return nil
}

func labVerifyMetricExporter(response labObject) error {
	if labField(response, "first_value") != float64(5) || labField(response, "first_batch") != float64(1) || labField(response, "first_calls") != float64(1) || labField(response, "first_flushed") != true || labField(response, "controlled_failure") != true || labField(response, "maximum_concurrent") != float64(1) || labField(response, "shutdown") != true || labField(response, "flush") != true {
		return fmt.Errorf("Go periodic metric exporter contract failed: %v", response)
	}
	if calls, _ := labField(response, "calls").(float64); calls < 10 {
		return fmt.Errorf("Go exporter received only %v batches", calls)
	}
	return nil
}

func labVerifyMetricExemplars(response labObject) error {
	if labField(response, "on_count") != float64(1) || labField(response, "off_count") != float64(0) || labField(response, "retained_filtered_attribute") != true || labField(response, "custom_reservoir_selected") != true || labField(response, "offer_valid") != true || !strings.Contains(fmt.Sprint(labField(response, "default_sum_reservoir")), "FixedSizeReservoir") || !strings.Contains(fmt.Sprint(labField(response, "default_histogram_reservoir")), "HistogramReservoir") {
		return fmt.Errorf("Go exemplar filters or custom reservoir failed: %v", response)
	}
	return nil
}

func labVerifyPrometheus(response labObject) error {
	output, _ := labField(response, "text").(string)
	for _, line := range []string{
		"# HELP target_info Target metadata",
		"# TYPE target_info gauge",
		"# HELP lab_requests_total Lab requests",
		"# TYPE lab_requests_total counter",
		"# HELP lab_active Active lab requests",
		"# TYPE lab_active gauge",
		"# HELP lab_temperature Lab temperature",
		"# TYPE lab_temperature gauge",
		"# HELP lab_duration_milliseconds Lab duration",
		"# TYPE lab_duration_milliseconds histogram",
	} {
		if !strings.Contains(output, line+"\n") {
			return fmt.Errorf("Prometheus text lacks %q", line)
		}
	}
	for _, fragment := range []string{
		"target_info{lab_resource=\"yes\"", "service_name=\"lab-prom\"",
		"lab_requests_total{lab_route=\"one\"", "otel_scope_name=\"lab.prom.scope\"",
		"otel_scope_version=\"1.2.3\"", "lab_active{lab_route=\"one\"",
		"lab_temperature{lab_route=\"one\"", "lab_duration_milliseconds_bucket{lab_route=\"one\"",
		"lab_duration_milliseconds_count{lab_route=\"one\"", "lab_duration_milliseconds_sum{lab_route=\"one\"",
	} {
		if !strings.Contains(output, fragment) {
			return fmt.Errorf("Prometheus text lacks %q", fragment)
		}
	}
	if !strings.Contains(output, "} 5.0\n") || !strings.Contains(output, "} 21.0\n") || !strings.Contains(output, "} 12.0\n") {
		return fmt.Errorf("Prometheus counter, gauge, or histogram value is wrong")
	}
	for _, line := range strings.Split(output, "\n") {
		if !strings.HasPrefix(line, "lab_") {
			continue
		}
		if !strings.Contains(line, "otel_scope_name=\"lab.prom.scope\"") || !strings.Contains(line, "otel_scope_version=\"1.2.3\"") {
			return fmt.Errorf("Prometheus sample lacks scope labels: %s", line)
		}
	}
	return nil
}

func labVerifySDKTrace(response labObject) error {
	parent := "0102030405060708"
	if labField(response, "parent_id") != parent || labField(response, "sampler_parent_id") != parent || labField(response, "processor_parent_id") != parent {
		return fmt.Errorf("sampler or span processor lost the full remote parent context")
	}
	if labField(response, "sampler_marker") != "context-marker" || labField(response, "processor_marker") != "context-marker" || labField(response, "span_state") != "sampled" {
		return fmt.Errorf("custom sampler did not receive context or modify tracestate")
	}
	if labField(response, "scope") != "lab.sdk.scope" || labField(response, "scope_attributes") != true || labField(response, "flushed") != true || labField(response, "shut") != true || labField(response, "exported") != float64(1) {
		return fmt.Errorf("processor scope, flush, shutdown, or in-memory export is wrong")
	}
	id, _ := labField(response, "nonrecording_id").(string)
	if id == "" || id == parent || labField(response, "nonrecording_valid") != true || labField(response, "nonrecording_recording") != false {
		return fmt.Errorf("non-recording span did not receive a fresh valid ID")
	}
	return nil
}

func main() {
	appSuffix := flag.String("app-suffix", "", "application service label suffix")
	sinkSuffix := flag.String("sink-suffix", "", "sink service label suffix")
	language := flag.String("language", "", "python, ruby, or go")
	scenario := flag.String("scenario", "base", "base, links-count, or link-attributes")
	sourcePath := flag.String("source", "", "standalone application source runfile")
	sourceExtraPath := flag.String("source-extra", "", "additional application source runfile")
	sourceExtra2Path := flag.String("source-extra2", "", "second additional application source runfile")
	proofPlanPath := flag.String("proof-plan", "", "normalized telemetry-lab proof plan runfile")
	flag.Parse()
	if *appSuffix == "" || *sinkSuffix == "" || *sourcePath == "" || *proofPlanPath == "" || (*language != "python" && *language != "ruby" && *language != "go") {
		fmt.Fprintln(os.Stderr, "app-suffix, sink-suffix, source, proof-plan, and python/ruby/go language are required")
		os.Exit(2)
	}
	if *scenario != "base" && (*language != "python" || labVariantClaims[*scenario] == nil) {
		fmt.Fprintln(os.Stderr, "non-base scenario must be a registered Python variant")
		os.Exit(2)
	}
	planBytes, err := labSource(*proofPlanPath)
	if err != nil {
		panic(err)
	}
	plannedProofs, err := labPlanProofs(planBytes, *language, *scenario)
	if err != nil {
		panic(err)
	}
	source, err := labSource(*sourcePath)
	if err != nil {
		panic(err)
	}
	if *sourceExtraPath != "" {
		extra, err := labSource(*sourceExtraPath)
		if err != nil {
			panic(err)
		}
		source = append(append(source, 0), extra...)
	}
	if *sourceExtra2Path != "" {
		extra, err := labSource(*sourceExtra2Path)
		if err != nil {
			panic(err)
		}
		source = append(append(source, 0), extra...)
	}
	appPort, err := labPort(*appSuffix)
	if err != nil {
		panic(err)
	}
	sinkPort, err := labPort(*sinkSuffix)
	if err != nil {
		panic(err)
	}
	app := fmt.Sprintf("http://127.0.0.1:%d", appPort)
	sink := fmt.Sprintf("http://127.0.0.1:%d", sinkPort)
	client := &http.Client{Timeout: 5 * time.Second}
	if _, err := labRequest(client, "POST", sink+"/reset"); err != nil {
		panic(err)
	}
	paths := []string{"/v1/spans", "/v1/exceptions", "/v1/baggage"}
	if *language == "python" || *language == "go" {
		paths = []string{"/v1/spans", "/v1/exceptions", "/v1/metrics", "/v1/propagation"}
	}
	if *language == "python" {
		paths = append(paths, "/v1/lifecycle", "/v1/log-sdk", "/v1/trace-exporter", "/v1/propagation-custom", "/v1/prometheus")
	}
	if *language == "go" {
		paths = []string{"/v1/spans", "/v1/exceptions", "/v1/propagation", "/v1/concurrency", "/v1/resources", "/v1/metric-views", "/v1/metric-advanced", "/v1/metric-exporter", "/v1/metric-exemplars", "/v1/sdk-trace"}
	}
	responses := map[string]labObject{}
	for _, path := range paths {
		body, err := labRequest(client, "GET", app+path)
		if err != nil {
			panic(err)
		}
		var response labObject
		if err := json.Unmarshal(body, &response); err != nil {
			panic(err)
		}
		responses[path] = response
		switch path {
		case "/v1/sdk-trace":
			if err := labVerifySDKTrace(response); err != nil {
				panic(err)
			}
		case "/v1/metric-views":
			if err := labVerifyMetricViews(response); err != nil {
				panic(err)
			}
		case "/v1/metric-advanced":
			if err := labVerifyMetricAdvanced(response); err != nil {
				panic(err)
			}
		case "/v1/metric-exporter":
			if err := labVerifyMetricExporter(response); err != nil {
				panic(err)
			}
		case "/v1/metric-exemplars":
			if err := labVerifyMetricExemplars(response); err != nil {
				panic(err)
			}
		case "/v1/resources":
			merged, _ := labField(response, "merged").(map[string]any)
			if labField(response, "empty") != float64(0) || labField(merged, "lab.left") != "one" || labField(merged, "lab.right") != "two" {
				panic(fmt.Errorf("Go empty or merged resource result is wrong: %s", body))
			}
		case "/v1/concurrency":
			if labField(response, "workers") != float64(32) {
				panic(fmt.Errorf("Go concurrent request did not complete: %s", body))
			}
		case "/v1/lifecycle":
			if labField(response, "before") != true || labField(response, "after") != false || labField(response, "attached") != "attached-value" || labField(response, "detached") != nil {
				panic(fmt.Errorf("Python context and span lifecycle response: %s", body))
			}
		case "/v1/log-sdk":
			if labField(response, "count") != float64(1) || labField(response, "scope_name") != "lab.custom.log" || labField(response, "scope_attribute") != "logged" || labField(response, "body") != "lab direct log" || labField(response, "processor_emitted") != float64(1) || labField(response, "processor_flushed") != true || labField(response, "processor_shutdown") != true || labField(response, "exporter_shutdown") != true || labField(response, "exporter_flushed") != true || labField(response, "provider_flushed") != true {
				panic(fmt.Errorf("Python direct log SDK response: %s", body))
			}
		case "/v1/trace-exporter":
			if labField(response, "count") != float64(1) || labField(response, "name") != "lab.exported" || labField(response, "flushed") != true || labField(response, "exporter_flushed") != true || labField(response, "shutdown") != true {
				panic(fmt.Errorf("Python custom span exporter response: %s", body))
			}
		case "/v1/prometheus":
			if err := labVerifyPrometheus(response); err != nil {
				panic(err)
			}
		case "/v1/propagation-custom":
			calls, _ := labField(response, "get_calls").([]any)
			keys, _ := labField(response, "keys").([]any)
			setCalls, _ := labField(response, "set_calls").([]any)
			outgoing, _ := labField(response, "outgoing").(map[string]any)
			if labField(response, "remote") != true || len(calls) < 1 || len(keys) != 2 || len(setCalls) < 1 || labField(outgoing, "traceparent") == nil || labField(outgoing, "baggage") == nil || labField(response, "environment_remote") != true || labField(response, "environment_traceparent") == nil {
				panic(fmt.Errorf("Python custom propagation carrier response: %s", body))
			}
		case "/v1/propagation":
			if labField(response, "remote_parent") != true || labField(response, "baggage") != "lab-value" {
				panic(fmt.Errorf("context extraction or baggage failed: %s", body))
			}
			carrier, _ := labField(response, "carrier").(map[string]any)
			if !strings.Contains(fmt.Sprint(labField(carrier, "baggage")), "lab-key=lab-value") || labField(carrier, "traceparent") == nil {
				panic(fmt.Errorf("context injection failed: %s", body))
			}
		case "/v1/baggage":
			if labField(response, "baggage") != "lab-value" {
				panic(fmt.Errorf("Ruby baggage API failed: %s", body))
			}
		}
	}
	var capture []byte
	deadline := time.Now().Add(8 * time.Second)
	for time.Now().Before(deadline) {
		capture, err = labRequest(client, "GET", sink+"/dump")
		if err == nil {
			err = labVerify(capture, *language, *scenario)
		}
		if err == nil {
			break
		}
		time.Sleep(100 * time.Millisecond)
	}
	if err != nil {
		panic(err)
	}
	responseBytes, err := json.MarshalIndent(responses, "", "  ")
	if err != nil {
		panic(err)
	}
	responseBytes = append(responseBytes, '\n')
	if output := os.Getenv("TEST_UNDECLARED_OUTPUTS_DIR"); output != "" {
		artifact := *language + "-telemetry-lab"
		if *scenario != "base" {
			artifact += "-" + *scenario
		}
		if err := os.WriteFile(filepath.Join(output, artifact+".capture.json"), capture, 0o644); err != nil {
			panic(err)
		}
		if err := os.WriteFile(filepath.Join(output, artifact+".responses.json"), responseBytes, 0o644); err != nil {
			panic(err)
		}
		claims := labClaims[*language]
		if *scenario != "base" {
			claims = labVariantClaims[*scenario]
		}
		evidence := labProofEvidence{
			SchemaVersion:  1,
			Language:       *language,
			Scenario:       *scenario,
			CaptureSHA256:  fmt.Sprintf("%x", sha256.Sum256(capture)),
			SourceSHA256:   fmt.Sprintf("%x", sha256.Sum256(source)),
			ResponseSHA256: fmt.Sprintf("%x", sha256.Sum256(responseBytes)),
			FeatureIDs:     claims,
		}
		encoded, err := json.MarshalIndent(evidence, "", "  ")
		if err != nil {
			panic(err)
		}
		if err := os.WriteFile(filepath.Join(output, artifact+".proofs.json"), append(encoded, '\n'), 0o644); err != nil {
			panic(err)
		}
	}
	if err := labWriteReceipt(os.Getenv("TEST_UNDECLARED_OUTPUTS_DIR"), *language, *scenario, planBytes, capture, responseBytes, plannedProofs); err != nil {
		panic(err)
	}
	fmt.Printf("%s telemetry lab capture verified, sha256=%x\n", *language, sha256.Sum256(bytes.TrimSpace(capture)))
}
