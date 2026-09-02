package main

import (
	"bytes"
	"crypto/sha256"
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"sort"
	"strconv"
	"strings"
	"time"
)

func main() {
	baseURL := flag.String("base-url", "", "API origin to test, for example http://127.0.0.1:8000")
	host := flag.String("host", "127.0.0.1", "API host when --port is used")
	portFlag := flag.Int("port", 0, "API port (alternative to --base-url)")
	serviceSuffix := flag.String("service-suffix", "", "rules_itest service label suffix used to discover an assigned port")
	otelSinkSuffix := flag.String("otel-sink-suffix", "", "OTLP sink service suffix whose decoded telemetry dump must become non-empty")
	otelProfileManifest := flag.String("otel-profile-manifest", "", "atomic OpenTelemetry profile manifest")
	otelMode := flag.String("otel-mode", "validate", "OTLP profile mode: validate or shape candidate")
	otelCase := flag.String("otel-case", "", "RealWorld scenario name")
	otelXFail := flag.String("otel-xfail", "", "reason this case is expected to violate its OTLP contract")
	hurlRootfs := flag.String("hurl-rootfs", "harness/hurl_rootfs", "Hurl OCI rootfs in runfiles")
	jobs := flag.Int("jobs", 4, "number of Hurl files to execute concurrently")
	uid := flag.String("uid", "", "unique suffix used for API objects")
	flag.Parse()
	if *jobs < 1 {
		fatal(errors.New("--jobs must be at least 1"))
	}

	endpoint := strings.TrimSuffix(*baseURL, "/")
	if endpoint == "" && *portFlag != 0 {
		endpoint = fmt.Sprintf("http://%s:%d", *host, *portFlag)
	}
	if endpoint == "" && *serviceSuffix != "" {
		port, err := assignedPort(*serviceSuffix)
		if err != nil {
			fatal(err)
		}
		endpoint = fmt.Sprintf("http://127.0.0.1:%d", port)
	}
	if endpoint == "" {
		fatal(errors.New("one of --base-url, --port, or --service-suffix is required"))
	}

	rootfs, err := resolvePath(*hurlRootfs, true)
	if err != nil {
		fatal(fmt.Errorf("resolve Hurl rootfs: %w", err))
	}

	specValues := flag.Args()
	if len(specValues) == 0 {
		specValues, err = bundledSpecs()
		if err != nil {
			fatal(err)
		}
	}
	specs := make([]string, 0, len(specValues))
	for _, value := range specValues {
		spec, resolveErr := resolvePath(value, false)
		if resolveErr != nil {
			fatal(fmt.Errorf("resolve Hurl spec %q: %w", value, resolveErr))
		}
		specs = append(specs, spec)
	}

	objectUID := *uid
	if objectUID == "" {
		objectUID = fmt.Sprintf("rules_stests_%d", os.Getpid())
	}
	loader := filepath.Join(rootfs, "lib", "ld-musl-x86_64.so.1")
	hurl := filepath.Join(rootfs, "usr", "bin", "hurl")
	libraryPath := strings.Join([]string{filepath.Join(rootfs, "lib"), filepath.Join(rootfs, "usr", "lib")}, ":")
	args := []string{
		"--library-path",
		libraryPath,
		hurl,
		"--test",
		"--jobs",
		strconv.Itoa(*jobs),
		"--error-format",
		"long",
		"--variable",
		"host=" + endpoint,
		"--variable",
		"uid=" + objectUID,
	}
	args = append(args, specs...)
	if *otelSinkSuffix != "" {
		if err := resetStartupTelemetry(*otelSinkSuffix); err != nil {
			fatal(err)
		}
	}
	command := exec.Command(loader, args...)
	command.Env = append(os.Environ(), "NO_COLOR=1")
	command.Stdout = os.Stdout
	command.Stderr = os.Stderr
	if err := command.Run(); err != nil {
		fatal(fmt.Errorf("RealWorld Hurl suite failed: %w", err))
	}
	if *otelSinkSuffix != "" {
		profile, err := loadAtomicProfile(*otelProfileManifest, *otelCase, *otelMode)
		if err != nil {
			fatal(err)
		}
		validationErr := requireExportedTelemetry(*otelSinkSuffix, *otelMode, *otelCase, profile)
		if err := classifyOTLPValidation(validationErr, *otelXFail, *otelCase, os.Stderr); err != nil {
			fatal(err)
		}
		if validationErr != nil {
			var assertionFailure *otlpAssertionFailure
			if !errors.As(validationErr, &assertionFailure) {
				fatal(errors.New("internal error: accepted OTLP xfail is not an assertion failure"))
			}
			if err := emitExpectedFailureReceipt(profile, assertionFailure.capture, *otelXFail); err != nil {
				fatal(err)
			}
		}
	}
	fmt.Printf("RealWorld Hurl suite passed against %s (%d files, %d jobs)\n", endpoint, len(specs), *jobs)
}

type sinkStats struct {
	Records                  int `json:"records"`
	TraceRequests            int `json:"trace_requests"`
	TraceSpans               int `json:"trace_spans"`
	MetricRequests           int `json:"metric_requests"`
	LogRequests              int `json:"log_requests"`
	ValidationRuns           int `json:"validation_runs"`
	ValidationFailures       int `json:"validation_failures"`
	ValidationLastDurationMS int `json:"validation_last_duration_ms"`
	ValidationLastCalls      int `json:"validation_last_calls"`
	PeakRSSKiB               int `json:"peak_rss_kib"`
}

type sinkRecord struct {
	Signal  string          `json:"signal"`
	Payload json.RawMessage `json:"payload"`
}

type atomicProfileManifest struct {
	SchemaVersion  int               `json:"schemaVersion"`
	Profile        string            `json:"profile"`
	Signals        []string          `json:"signals"`
	ProofPlan      string            `json:"proofPlan"`
	Program        string            `json:"program"`
	Libraries      []string          `json:"libraries"`
	Imports        []string          `json:"imports"`
	ScenarioShapes map[string]string `json:"scenarioShapes"`
}

type proofPlanProof struct {
	FeatureID      string   `json:"featureId"`
	Assertion      string   `json:"assertion"`
	Basis          string   `json:"basis"`
	EvidencePolicy string   `json:"evidencePolicy"`
	Scenarios      []string `json:"scenarios"`
	Sources        []string `json:"sources"`
}

type normalizedProofPlan struct {
	SchemaVersion   int               `json:"schemaVersion"`
	Profile         string            `json:"profile"`
	DisplayName     string            `json:"displayName"`
	Language        string            `json:"language"`
	Framework       string            `json:"framework"`
	ServiceName     string            `json:"serviceName"`
	Signals         []string          `json:"signals"`
	Implementations []string          `json:"implementations"`
	Sources         map[string]string `json:"sources"`
	Proofs          []proofPlanProof  `json:"proofs"`
}

type atomicProfile struct {
	ID, Scenario, Program, ValidationMode string
	Signals                               map[string]bool
	Libraries, Imports                    []string
	Plan, Shape                           []byte
	ExpectedProofs                        []proofPlanProof
}

func loadAtomicProfile(value, scenario, mode string) (atomicProfile, error) {
	var profile atomicProfile
	if value == "" {
		return profile, errors.New("--otel-profile-manifest is required with --otel-sink-suffix")
	}
	if err := schemeIdentifier(scenario); err != nil {
		return profile, fmt.Errorf("invalid OTLP scenario: %w", err)
	}
	path, err := resolvePath(value, false)
	if err != nil {
		return profile, fmt.Errorf("resolve atomic profile: %w", err)
	}
	file, err := os.Open(path)
	if err != nil {
		return profile, err
	}
	decoder := json.NewDecoder(file)
	decoder.DisallowUnknownFields()
	var manifest atomicProfileManifest
	err = decoder.Decode(&manifest)
	file.Close()
	if err != nil {
		return profile, fmt.Errorf("decode atomic profile: %w", err)
	}
	if manifest.SchemaVersion != 1 || manifest.Profile == "" || manifest.ProofPlan == "" || manifest.Program == "" || len(manifest.Libraries) == 0 {
		return profile, errors.New("atomic profile manifest is incomplete")
	}
	if err := schemeIdentifier(manifest.Profile); err != nil {
		return profile, fmt.Errorf("invalid profile id: %w", err)
	}
	profile.ID, profile.Scenario = manifest.Profile, scenario
	profile.Signals, err = parseOTLPSignals(strings.Join(manifest.Signals, ","))
	if err != nil {
		return profile, err
	}
	profile.Libraries = append([]string(nil), manifest.Libraries...)
	profile.Imports = append([]string(nil), manifest.Imports...)
	profile.Program = manifest.Program
	profile.Plan = []byte(manifest.ProofPlan)
	profile.ValidationMode = "contract"
	if shape := manifest.ScenarioShapes[scenario]; shape != "" && mode != "candidate" {
		profile.ValidationMode, profile.Shape = "exact", []byte(shape)
		profile.Libraries = append(profile.Libraries, shape)
		profile.Imports = append(profile.Imports, "realworld.shape."+manifest.Profile+"."+scenario)
	}
	var plan normalizedProofPlan
	decoder = json.NewDecoder(bytes.NewReader(profile.Plan))
	decoder.DisallowUnknownFields()
	if err := decoder.Decode(&plan); err != nil {
		return profile, fmt.Errorf("decode normalized proof plan: %w", err)
	}
	if plan.SchemaVersion != 1 || plan.Profile != profile.ID {
		return profile, errors.New("normalized proof plan does not match profile")
	}
	for _, proof := range plan.Proofs {
		if len(proof.Scenarios) == 0 || containsString(proof.Scenarios, scenario) {
			profile.ExpectedProofs = append(profile.ExpectedProofs, proof)
		}
	}
	return profile, nil
}

type otlpAssertionFailure struct {
	cause   error
	capture []byte
}

func (failure *otlpAssertionFailure) Error() string {
	return failure.cause.Error()
}

func (failure *otlpAssertionFailure) Unwrap() error {
	return failure.cause
}

func classifyOTLPValidation(validationErr error, xfailReason, scenarioName string, output io.Writer) error {
	if xfailReason == "" {
		return validationErr
	}
	if validationErr == nil {
		return fmt.Errorf("XPASS: OTLP contract %s unexpectedly passed; remove its xfail (%s)", scenarioName, xfailReason)
	}
	var assertionFailure *otlpAssertionFailure
	if !errors.As(validationErr, &assertionFailure) {
		return fmt.Errorf("OTLP xfail %s applies only to contract assertions; infrastructure failed instead: %w", scenarioName, validationErr)
	}
	fmt.Fprintf(output, "XFAIL: OTLP contract %s violated as expected (%s):\n%v\n", scenarioName, xfailReason, validationErr)
	return nil
}

func resetStartupTelemetry(serviceSuffix string) error {
	port, err := assignedPort(serviceSuffix)
	if err != nil {
		return fmt.Errorf("locate OTLP sink for startup reset: %w", err)
	}
	baseURL := fmt.Sprintf("http://127.0.0.1:%d", port)
	client := http.Client{Timeout: 5 * time.Second}
	deadline := time.Now().Add(15 * time.Second)
	lastTraceRequests := -1
	lastTraceSpans := -1
	stableSince := time.Time{}
	for {
		stats, statsErr := readSinkStats(client, baseURL)
		if statsErr == nil {
			if stats.TraceRequests != lastTraceRequests || stats.TraceSpans != lastTraceSpans {
				lastTraceRequests = stats.TraceRequests
				lastTraceSpans = stats.TraceSpans
				stableSince = time.Now()
			} else if time.Since(stableSince) >= 2*time.Second {
				break
			}
		}
		if time.Now().After(deadline) {
			return fmt.Errorf("startup OTLP at %s did not quiesce before reset", baseURL)
		}
		time.Sleep(100 * time.Millisecond)
	}
	request, err := http.NewRequest(http.MethodPost, baseURL+"/reset/traces", nil)
	if err != nil {
		return fmt.Errorf("create startup OTLP reset request: %w", err)
	}
	response, err := client.Do(request)
	if err != nil {
		return fmt.Errorf("reset startup OTLP: %w", err)
	}
	contents, readErr := io.ReadAll(response.Body)
	response.Body.Close()
	if readErr != nil {
		return fmt.Errorf("read startup OTLP reset response: %w", readErr)
	}
	if response.StatusCode != http.StatusOK {
		return fmt.Errorf("reset startup OTLP: HTTP %d: %s", response.StatusCode, contents)
	}
	return nil
}

// parseOTLPSignals reads the set of signals an implementation is expected to
// export. Traces are always required; implementations whose instrumentation
// covers no metrics or logs declare a narrower set so quiescence does not wait
// for exports that will never arrive.
func parseOTLPSignals(value string) (map[string]bool, error) {
	signals := map[string]bool{}
	for _, name := range strings.Split(value, ",") {
		name = strings.TrimSpace(name)
		if name == "" {
			continue
		}
		if name != "traces" && name != "metrics" && name != "logs" {
			return nil, fmt.Errorf("unknown OTLP signal %q in --otel-signals", name)
		}
		signals[name] = true
	}
	if !signals["traces"] {
		return nil, errors.New("--otel-signals must include traces")
	}
	return signals, nil
}

func requireExportedTelemetry(serviceSuffix, mode, scenario string, profile atomicProfile) error {
	if mode != "validate" && mode != "candidate" {
		return fmt.Errorf("invalid --otel-mode %q", mode)
	}
	if err := schemeIdentifier(scenario); err != nil {
		return err
	}
	port, err := assignedPort(serviceSuffix)
	if err != nil {
		return fmt.Errorf("locate OTLP sink: %w", err)
	}
	baseURL := fmt.Sprintf("http://127.0.0.1:%d", port)
	deadline := time.Now().Add(time.Minute)
	lastTraceRequests := -1
	lastTraceSpans := -1
	lastStats := sinkStats{}
	lastRequestError := "none"
	stableSince := time.Time{}
	for {
		requestTimeout := time.Until(deadline)
		if requestTimeout <= 0 {
			return fmt.Errorf("OTLP sink at %s did not reach trace quiescence; last stats: %+v; last request error: %s", baseURL, lastStats, lastRequestError)
		}
		if requestTimeout > 5*time.Second {
			requestTimeout = 5 * time.Second
		}
		client := http.Client{Timeout: requestTimeout}
		response, requestErr := client.Get(baseURL + "/stats")
		if requestErr != nil {
			lastRequestError = requestErr.Error()
		}
		if requestErr == nil {
			contents, readErr := io.ReadAll(response.Body)
			response.Body.Close()
			if readErr == nil && response.StatusCode == http.StatusOK {
				var stats sinkStats
				if json.Unmarshal(contents, &stats) == nil {
					lastStats = stats
					lastRequestError = "none"
				}
				if stats.TraceSpans > 0 &&
					(!profile.Signals["metrics"] || stats.MetricRequests > 0) &&
					(!profile.Signals["logs"] || stats.LogRequests > 0) {
					if stats.TraceRequests != lastTraceRequests || stats.TraceSpans != lastTraceSpans {
						lastTraceRequests = stats.TraceRequests
						lastTraceSpans = stats.TraceSpans
						stableSince = time.Now()
					} else if !stableSince.IsZero() && time.Since(stableSince) >= 2*time.Second {
						return validateTelemetryDump(http.Client{Timeout: time.Minute}, baseURL, mode, scenario, profile, stats)
					}
				}
			}
		}
		if time.Now().After(deadline) {
			return fmt.Errorf("OTLP sink at %s did not reach trace quiescence; last stats: %+v; last request error: %s", baseURL, lastStats, lastRequestError)
		}
		time.Sleep(250 * time.Millisecond)
	}
}

func validateTelemetryDump(client http.Client, baseURL, mode, scenario string, profile atomicProfile, stats sinkStats) error {
	response, err := client.Get(baseURL + "/dump")
	if err != nil {
		return fmt.Errorf("read quiescent OTLP dump: %w", err)
	}
	defer response.Body.Close()
	contents, err := io.ReadAll(response.Body)
	if err != nil {
		return fmt.Errorf("read quiescent OTLP dump body: %w", err)
	}
	if response.StatusCode != http.StatusOK {
		return fmt.Errorf("read quiescent OTLP dump: HTTP %d: %s", response.StatusCode, contents)
	}
	var records []sinkRecord
	if err := json.Unmarshal(contents, &records); err != nil {
		return fmt.Errorf("decode quiescent OTLP dump: %w", err)
	}
	seen := map[string]bool{}
	for _, record := range records {
		if payloadHasServiceName(record.Payload, record.Signal) {
			seen[record.Signal] = true
		}
	}
	for signal := range profile.Signals {
		if !seen[signal] {
			emitFailedCapture(profile.ID+"/"+scenario, contents)
			return &otlpAssertionFailure{cause: fmt.Errorf("OTLP dump at %s lacks %s with service.name", baseURL, signal), capture: append([]byte(nil), contents...)}
		}
	}
	source, err := readSchemeBundle(profile.Libraries, profile.Imports, profile.Program, scenario, profile.ValidationMode)
	if err != nil {
		return err
	}
	started := time.Now()
	request, err := http.NewRequest(http.MethodPost, baseURL+"/validate", bytes.NewReader(source))
	if err != nil {
		return fmt.Errorf("create Scheme validation request: %w", err)
	}
	request.Header.Set("Content-Type", "text/x-scheme")
	validationResponse, err := client.Do(request)
	if err != nil {
		return fmt.Errorf("run Scheme validation: %w", err)
	}
	validationOutput, readErr := io.ReadAll(validationResponse.Body)
	validationResponse.Body.Close()
	elapsed := time.Since(started).Round(time.Millisecond)
	if current, statsErr := readSinkStats(client, baseURL); statsErr == nil {
		fmt.Printf("Stak Scheme validation usage: wall=%s sink=%dms calls=%d peak_rss=%.1f MiB\n", elapsed, current.ValidationLastDurationMS, current.ValidationLastCalls, float64(current.PeakRSSKiB)/1024)
	} else {
		fmt.Printf("Stak Scheme validation usage: wall=%s stats_unavailable=%v\n", elapsed, statsErr)
	}
	if readErr != nil {
		return fmt.Errorf("read Scheme validation result: %w", readErr)
	}
	if validationResponse.StatusCode != http.StatusOK {
		emitFailedCapture(profile.ID+"/"+scenario, contents)
		failure := schemeValidationFailure(validationResponse.StatusCode, validationOutput)
		var assertionFailure *otlpAssertionFailure
		if errors.As(failure, &assertionFailure) {
			assertionFailure.capture = append([]byte(nil), contents...)
		}
		return failure
	}
	proofs, err := validateProofSet(profile.ExpectedProofs, validationOutput)
	if err != nil {
		emitFailedCapture(profile.ID+"/"+scenario, contents)
		return &otlpAssertionFailure{cause: err, capture: append([]byte(nil), contents...)}
	}
	if mode == "candidate" {
		if err := emitShapeCandidate(client, baseURL, scenario, profile.ID, contents); err != nil {
			return err
		}
		fmt.Printf("Validated OTLP contract and emitted shape candidate for %s/%s: %d spans in %d trace requests\n", profile.ID, scenario, stats.TraceSpans, stats.TraceRequests)
		return nil
	}
	if err := emitValidationReceipt(profile, contents, proofs); err != nil {
		return err
	}
	fmt.Printf("Verified quiescent OTLP profile: %d spans in %d trace requests (%s): %s", stats.TraceSpans, stats.TraceRequests, baseURL, validationOutput)
	return nil
}

var proofMarker = regexp.MustCompile(`\[\[OTLP-PROOF-V1\|([^|\]]+)\|([^|\]]+)\|([^|\]]+)\]\]`)
var commitRevision = regexp.MustCompile(`^[0-9a-f]{40}$`)

type receiptProof struct {
	FeatureID string `json:"featureId"`
	Assertion string `json:"assertion"`
	Basis     string `json:"basis"`
	Result    string `json:"result"`
}

type validationReceipt struct {
	SchemaVersion       int            `json:"schemaVersion"`
	Revision            string         `json:"revision"`
	Profile             string         `json:"profile"`
	Scenario            string         `json:"scenario"`
	ProofPlanSHA256     string         `json:"proofPlanSha256"`
	CaptureSHA256       string         `json:"captureSha256"`
	ValidationMode      string         `json:"validationMode"`
	Outcome             string         `json:"outcome"`
	XFailReason         string         `json:"xfailReason,omitempty"`
	ScenarioShapeSHA256 string         `json:"scenarioShapeSha256,omitempty"`
	Proofs              []receiptProof `json:"proofs"`
}

func validateProofSet(expected []proofPlanProof, output []byte) ([]receiptProof, error) {
	actual := map[string]receiptProof{}
	for _, match := range proofMarker.FindAllSubmatch(output, -1) {
		proof := receiptProof{FeatureID: string(match[1]), Assertion: string(match[2]), Basis: string(match[3]), Result: "pass"}
		key := proof.FeatureID + "\x00" + proof.Assertion + "\x00" + proof.Basis
		if _, exists := actual[key]; exists {
			return nil, fmt.Errorf("duplicate executed proof for %s/%s", proof.FeatureID, proof.Assertion)
		}
		actual[key] = proof
	}
	wanted := map[string]proofPlanProof{}
	for _, proof := range expected {
		key := proof.FeatureID + "\x00" + proof.Assertion + "\x00" + proof.Basis
		if _, exists := wanted[key]; exists {
			return nil, fmt.Errorf("normalized plan duplicates proof %s", proof.FeatureID)
		}
		wanted[key] = proof
	}
	if len(actual) != len(wanted) {
		return nil, fmt.Errorf("executed proof set has %d entries, normalized plan requires %d", len(actual), len(wanted))
	}
	keys := make([]string, 0, len(wanted))
	for key := range wanted {
		if _, ok := actual[key]; !ok {
			proof := wanted[key]
			return nil, fmt.Errorf("missing proof %s/%s (%s)", proof.FeatureID, proof.Assertion, proof.Basis)
		}
		keys = append(keys, key)
	}
	for key, proof := range actual {
		if _, ok := wanted[key]; !ok {
			return nil, fmt.Errorf("unexpected proof %s/%s", proof.FeatureID, proof.Assertion)
		}
	}
	sort.Strings(keys)
	proofs := make([]receiptProof, 0, len(keys))
	for _, key := range keys {
		proofs = append(proofs, actual[key])
	}
	return proofs, nil
}

func emitValidationReceipt(profile atomicProfile, capture []byte, proofs []receiptProof) error {
	return emitReceipt(profile, capture, proofs, "verified", "")
}

func emitExpectedFailureReceipt(profile atomicProfile, capture []byte, reason string) error {
	if reason == "" {
		return errors.New("an OTLP xfail receipt requires a reason")
	}
	if len(capture) == 0 {
		return errors.New("an OTLP xfail receipt requires the rejected capture")
	}
	return emitReceipt(profile, capture, []receiptProof{}, "xfail", reason)
}

func emitReceipt(profile atomicProfile, capture []byte, proofs []receiptProof, outcome, xfailReason string) error {
	revision := os.Getenv("OTEL_TEST_REVISION")
	if revision == "" {
		return nil
	}
	if !commitRevision.MatchString(revision) {
		return errors.New("a lowercase 40-character current revision is required to emit an OTLP receipt")
	}
	root := os.Getenv("TEST_UNDECLARED_OUTPUTS_DIR")
	if root == "" {
		return errors.New("TEST_UNDECLARED_OUTPUTS_DIR is unavailable for OTLP receipt")
	}
	planDigest, captureDigest := sha256.Sum256(profile.Plan), sha256.Sum256(capture)
	receipt := validationReceipt{
		SchemaVersion: 1, Revision: revision, Profile: profile.ID, Scenario: profile.Scenario,
		ProofPlanSHA256: fmt.Sprintf("%x", planDigest), CaptureSHA256: fmt.Sprintf("%x", captureDigest),
		ValidationMode: profile.ValidationMode, Outcome: outcome, XFailReason: xfailReason, Proofs: proofs,
	}
	if profile.ValidationMode == "exact" {
		digest := sha256.Sum256(profile.Shape)
		receipt.ScenarioShapeSHA256 = fmt.Sprintf("%x", digest)
	}
	encoded, err := json.MarshalIndent(receipt, "", "  ")
	if err != nil {
		return err
	}
	encoded = append(encoded, '\n')
	directory := filepath.Join(root, "receipts", profile.ID)
	if err := os.MkdirAll(directory, 0o755); err != nil {
		return err
	}
	path := filepath.Join(directory, profile.Scenario+".json")
	if err := os.WriteFile(path, encoded, 0o644); err != nil {
		return fmt.Errorf("write OTLP receipt: %w", err)
	}
	capturePath := filepath.Join(directory, profile.Scenario+".capture.json")
	if err := os.WriteFile(capturePath, capture, 0o644); err != nil {
		_ = os.Remove(path)
		return fmt.Errorf("write accepted OTLP capture: %w", err)
	}
	return nil
}

func containsString(values []string, wanted string) bool {
	for _, value := range values {
		if value == wanted {
			return true
		}
	}
	return false
}

func payloadHasServiceName(payload json.RawMessage, signal string) bool {
	var document map[string]any
	if json.Unmarshal(payload, &document) != nil {
		return false
	}
	var wrapperNames []string
	switch signal {
	case "traces":
		wrapperNames = []string{"resource_spans", "resourceSpans"}
	case "metrics":
		wrapperNames = []string{"resource_metrics", "resourceMetrics"}
	case "logs":
		wrapperNames = []string{"resource_logs", "resourceLogs"}
	default:
		return false
	}
	wrappers, _ := mapValue(document, wrapperNames...).([]any)
	for _, wrapperValue := range wrappers {
		wrapper, _ := wrapperValue.(map[string]any)
		if !wrapperHasSignalItems(wrapper, signal) {
			continue
		}
		resource, _ := wrapper["resource"].(map[string]any)
		attributes, _ := resource["attributes"].([]any)
		for _, attributeValue := range attributes {
			attribute, _ := attributeValue.(map[string]any)
			if attribute["key"] != "service.name" {
				continue
			}
			value, _ := attribute["value"].(map[string]any)
			if nested, ok := value["value"].(map[string]any); ok {
				value = nested
			}
			name, _ := mapValue(value, "string_value", "stringValue").(string)
			if name != "" {
				return true
			}
		}
	}
	return false
}

func wrapperHasSignalItems(wrapper map[string]any, signal string) bool {
	var groupNames, itemNames []string
	switch signal {
	case "traces":
		groupNames = []string{"scope_spans", "scopeSpans"}
		itemNames = []string{"spans"}
	case "metrics":
		groupNames = []string{"scope_metrics", "scopeMetrics"}
		itemNames = []string{"metrics"}
	case "logs":
		groupNames = []string{"scope_logs", "scopeLogs"}
		itemNames = []string{"log_records", "logRecords"}
	default:
		return false
	}
	groups, _ := mapValue(wrapper, groupNames...).([]any)
	for _, groupValue := range groups {
		group, _ := groupValue.(map[string]any)
		items, _ := mapValue(group, itemNames...).([]any)
		if len(items) > 0 {
			return true
		}
	}
	return false
}

func mapValue(object map[string]any, names ...string) any {
	for _, name := range names {
		if value, ok := object[name]; ok {
			return value
		}
	}
	return nil
}

func schemeValidationFailure(status int, output []byte) error {
	failure := fmt.Errorf("Scheme rejected OTLP capture (HTTP %d):\n%s", status, output)
	if status == http.StatusConflict {
		return &otlpAssertionFailure{cause: failure}
	}
	return failure
}

func readSinkStats(client http.Client, baseURL string) (sinkStats, error) {
	response, err := client.Get(baseURL + "/stats")
	if err != nil {
		return sinkStats{}, err
	}
	defer response.Body.Close()
	if response.StatusCode != http.StatusOK {
		contents, _ := io.ReadAll(response.Body)
		return sinkStats{}, fmt.Errorf("HTTP %d: %s", response.StatusCode, contents)
	}
	var stats sinkStats
	if err := json.NewDecoder(response.Body).Decode(&stats); err != nil {
		return sinkStats{}, err
	}
	return stats, nil
}

func readSchemeBundle(libraries, imports []string, programValue, scenario, validationMode string) ([]byte, error) {
	var source []byte
	for _, item := range libraries {
		source = append(source, item...)
		source = append(source, '\n')
	}
	source = append(source, []byte("(import (scheme base) (scheme read)")...)
	for _, name := range imports {
		declaration, err := schemeLibraryName(name)
		if err != nil {
			return nil, err
		}
		source = append(source, ' ')
		source = append(source, declaration...)
	}
	source = append(source, []byte(")\n")...)
	if err := schemeIdentifier(scenario); err != nil {
		return nil, fmt.Errorf("invalid OTLP scenario: %w", err)
	}
	source = append(source, []byte("(define scenario-name '")...)
	source = append(source, scenario...)
	source = append(source, []byte(")\n")...)
	source = append(source, []byte("(define validation-mode '")...)
	source = append(source, validationMode...)
	source = append(source, []byte(")\n")...)
	if validationMode != "exact" {
		source = append(source, []byte("(define scenario-shape '())\n")...)
	}
	source = append(source, programValue...)
	source = append(source, '\n')
	return source, nil
}

func schemeIdentifier(value string) error {
	if value == "" {
		return errors.New("Scheme identifier is empty")
	}
	for index, character := range value {
		letter := (character >= 'a' && character <= 'z') ||
			(character >= 'A' && character <= 'Z')
		if index == 0 && !letter && character != '_' {
			return fmt.Errorf("invalid Scheme identifier %q", value)
		}
		if !((character >= 'a' && character <= 'z') ||
			(character >= 'A' && character <= 'Z') ||
			(character >= '0' && character <= '9') ||
			strings.ContainsRune("-+_", character)) {
			return fmt.Errorf("invalid Scheme identifier %q", value)
		}
	}
	return nil
}

func schemeLibraryName(value string) ([]byte, error) {
	parts := strings.Split(value, ".")
	if len(parts) == 0 {
		return nil, errors.New("Scheme library name is empty")
	}
	for _, part := range parts {
		if part == "" {
			return nil, fmt.Errorf("invalid Scheme library name %q", value)
		}
		for _, character := range part {
			if !((character >= 'a' && character <= 'z') ||
				(character >= 'A' && character <= 'Z') ||
				(character >= '0' && character <= '9') ||
				strings.ContainsRune("-+_", character)) {
				return nil, fmt.Errorf("invalid Scheme library name %q", value)
			}
		}
	}
	return []byte("(" + strings.Join(parts, " ") + ")"), nil
}

func emitShapeCandidate(client http.Client, baseURL, scenario, profile string, capture []byte) error {
	app := profile
	if strings.Contains(profile, "aiohttp") {
		app = "aiohttp"
	}
	if strings.Contains(profile, "django") {
		app = "django"
	}
	if strings.Contains(profile, "gin") {
		app = "gin"
	}
	response, err := client.Get(baseURL + "/candidate?app=" + url.QueryEscape(app))
	if err != nil {
		return fmt.Errorf("generate OTLP Scheme shape candidate: %w", err)
	}
	shape, readErr := io.ReadAll(response.Body)
	response.Body.Close()
	if readErr != nil {
		return fmt.Errorf("read OTLP Scheme shape candidate: %w", readErr)
	}
	if response.StatusCode != http.StatusOK {
		return fmt.Errorf("generate OTLP Scheme shape candidate: HTTP %d: %s", response.StatusCode, shape)
	}
	shape = append([]byte(fmt.Sprintf("(define-library (realworld shape %s %s)\n  (export scenario-shape)\n  (import (scheme base) (otel trace-shape))\n  (begin\n", profile, scenario)), shape...)
	shape = append(shape, []byte("  ))\n")...)
	root := os.Getenv("TEST_UNDECLARED_OUTPUTS_DIR")
	if root == "" {
		return errors.New("TEST_UNDECLARED_OUTPUTS_DIR is unavailable for shape candidate")
	}
	directory := filepath.Join(root, "shape", profile)
	if err := os.MkdirAll(directory, 0o755); err != nil {
		return fmt.Errorf("create shape candidate output directory: %w", err)
	}
	capturePath := filepath.Join(directory, scenario+".capture.json")
	shapePath := filepath.Join(directory, scenario+".scm")
	if err := os.WriteFile(capturePath, capture, 0o644); err != nil {
		return fmt.Errorf("write raw candidate capture: %w", err)
	}
	if err := os.WriteFile(shapePath, shape, 0o644); err != nil {
		return fmt.Errorf("write Scheme shape candidate: %w", err)
	}
	return nil
}

func emitFailedCapture(scenarioName string, capture []byte) {
	root := os.Getenv("TEST_UNDECLARED_OUTPUTS_DIR")
	if root == "" {
		return
	}
	name := strings.NewReplacer("/", "-", "\\", "-").Replace(scenarioName)
	if name == "" {
		name = "otel"
	}
	_ = os.WriteFile(filepath.Join(root, name+"-failed-capture.json"), capture, 0o644)
}

func fatal(err error) {
	fmt.Fprintln(os.Stderr, "realworld_hurl:", err)
	os.Exit(1)
}

func assignedPort(serviceSuffix string) (int, error) {
	var ports map[string]json.RawMessage
	if err := json.Unmarshal([]byte(os.Getenv("ASSIGNED_PORTS")), &ports); err != nil {
		return 0, fmt.Errorf("decode ASSIGNED_PORTS: %w", err)
	}
	for label, encoded := range ports {
		if !strings.HasSuffix(label, serviceSuffix) {
			continue
		}
		var port int
		if err := json.Unmarshal(encoded, &port); err == nil {
			return port, nil
		}
		var text string
		if err := json.Unmarshal(encoded, &text); err != nil {
			return 0, fmt.Errorf("decode assigned port for %s: %w", label, err)
		}
		port, err := strconv.Atoi(text)
		if err != nil {
			return 0, fmt.Errorf("decode assigned port for %s: %w", label, err)
		}
		return port, nil
	}
	return 0, fmt.Errorf("service ending in %q is absent from ASSIGNED_PORTS: %v", serviceSuffix, ports)
}

func resolvePath(value string, wantDirectory bool) (string, error) {
	if value == "" {
		return "", errors.New("path is empty")
	}
	candidates := []string{value}
	for _, root := range runfileRoots() {
		candidates = append(candidates, filepath.Join(root, value), filepath.Join(root, "_main", value))
	}
	for _, candidate := range candidates {
		info, err := os.Stat(candidate)
		if err != nil || info.IsDir() != wantDirectory {
			continue
		}
		return filepath.Abs(candidate)
	}
	return "", fmt.Errorf("%q is not present in runfiles", value)
}

func bundledSpecs() ([]string, error) {
	roots := append([]string{"."}, runfileRoots()...)
	patterns := []string{
		"+http_archive+realworld_api_specs/hurl/*.hurl",
		"external/+http_archive+realworld_api_specs/hurl/*.hurl",
	}
	for _, root := range roots {
		for _, pattern := range patterns {
			matches, err := filepath.Glob(filepath.Join(root, pattern))
			if err != nil {
				return nil, fmt.Errorf("locate bundled Hurl specs: %w", err)
			}
			if len(matches) != 0 {
				return matches, nil
			}
		}
	}
	return nil, errors.New("bundled RealWorld Hurl specs are absent from runfiles")
}

func runfileRoots() []string {
	roots := make([]string, 0, 5)
	add := func(path string) {
		if path == "" {
			return
		}
		for _, existing := range roots {
			if existing == path {
				return
			}
		}
		roots = append(roots, path)
		if filepath.Base(path) == "_main" {
			roots = append(roots, filepath.Dir(path))
		}
	}
	add(os.Getenv("RUNFILES_DIR"))
	add(os.Getenv("TEST_SRCDIR"))
	if executable, err := os.Executable(); err == nil {
		add(filepath.Join(filepath.Dir(executable), filepath.Base(executable)+".runfiles"))
	}
	return roots
}
