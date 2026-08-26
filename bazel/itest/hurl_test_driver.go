package main

import (
	"bytes"
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"io"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"strconv"
	"strings"
	"time"
)

type stringList []string

func (values *stringList) String() string {
	return strings.Join(*values, ",")
}

func (values *stringList) Set(value string) error {
	*values = append(*values, value)
	return nil
}

func main() {
	var otelLibraries stringList
	var otelImports stringList
	baseURL := flag.String("base-url", "", "API origin to test, for example http://127.0.0.1:8000")
	host := flag.String("host", "127.0.0.1", "API host when --port is used")
	portFlag := flag.Int("port", 0, "API port (alternative to --base-url)")
	serviceSuffix := flag.String("service-suffix", "", "rules_itest service label suffix used to discover an assigned port")
	otelSinkSuffix := flag.String("otel-sink-suffix", "", "OTLP sink service suffix whose decoded trace, metric, and log dump must become non-empty")
	flag.Var(&otelLibraries, "otel-library", "Scheme define-library source to include; repeatable")
	flag.Var(&otelImports, "otel-import", "dot-separated Scheme library name to import; repeatable")
	otelProgram := flag.String("otel-program", "", "Scheme validation program evaluated after importing the libraries")
	otelMode := flag.String("otel-mode", "validate", "OTLP golden mode: validate or candidate")
	otelCase := flag.String("otel-case", "", "OTLP golden identity in app/case form")
	hurlRootfs := flag.String("hurl-rootfs", "bazel/itest/hurl_rootfs", "Hurl OCI rootfs in runfiles")
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
	command := exec.Command(loader, args...)
	command.Env = append(os.Environ(), "NO_COLOR=1")
	command.Stdout = os.Stdout
	command.Stderr = os.Stderr
	if err := command.Run(); err != nil {
		fatal(fmt.Errorf("RealWorld Hurl suite failed: %w", err))
	}
	if *otelSinkSuffix != "" {
		if err := requireExportedTelemetry(*otelSinkSuffix, *otelMode, *otelCase, otelLibraries, otelImports, *otelProgram); err != nil {
			fatal(err)
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

func requireExportedTelemetry(serviceSuffix, mode, goldenCase string, libraries, imports []string, program string) error {
	if mode != "validate" && mode != "candidate" {
		return fmt.Errorf("invalid --otel-mode %q", mode)
	}
	if mode == "validate" && (len(libraries) == 0 || len(imports) == 0 || program == "") {
		return errors.New("--otel-library, --otel-import, and --otel-program are required in validate mode")
	}
	if mode == "candidate" && !strings.Contains(goldenCase, "/") {
		return errors.New("--otel-case must use app/case form in candidate mode")
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
				if stats.TraceSpans > 0 && stats.MetricRequests > 0 && stats.LogRequests > 0 {
					if stats.TraceRequests != lastTraceRequests || stats.TraceSpans != lastTraceSpans {
						lastTraceRequests = stats.TraceRequests
						lastTraceSpans = stats.TraceSpans
						stableSince = time.Now()
					} else if !stableSince.IsZero() && time.Since(stableSince) >= 2*time.Second {
						return validateTelemetryDump(http.Client{Timeout: time.Minute}, baseURL, mode, goldenCase, libraries, imports, program, stats)
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

func validateTelemetryDump(client http.Client, baseURL, mode, goldenCase string, libraries, imports []string, program string, stats sinkStats) error {
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
		if strings.Contains(string(record.Payload), `"service.name"`) {
			seen[record.Signal] = true
		}
	}
	if !seen["traces"] || !seen["metrics"] || !seen["logs"] {
		return fmt.Errorf("OTLP dump at %s lacks traces, metrics, or logs with service.name", baseURL)
	}
	if mode == "candidate" {
		if err := emitGoldenCandidate(client, baseURL, goldenCase, contents); err != nil {
			return err
		}
		fmt.Printf("Emitted OTLP golden candidate for %s: %d spans in %d trace requests, plus metrics and logs\n", goldenCase, stats.TraceSpans, stats.TraceRequests)
		return nil
	}
	source, err := readSchemeBundle(libraries, imports, program)
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
		emitFailedCapture(goldenCase, contents)
		return fmt.Errorf("Scheme rejected OTLP capture (HTTP %d):\n%s", validationResponse.StatusCode, validationOutput)
	}
	fmt.Printf("Verified quiescent OTLP Scheme golden: %d spans in %d trace requests, plus metrics and logs (%s): %s", stats.TraceSpans, stats.TraceRequests, baseURL, validationOutput)
	return nil
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

func readSchemeBundle(libraries, imports []string, programValue string) ([]byte, error) {
	var source []byte
	for _, item := range libraries {
		path, err := resolvePath(item, false)
		if err != nil {
			return nil, fmt.Errorf("resolve Scheme library %q: %w", item, err)
		}
		contents, err := os.ReadFile(path)
		if err != nil {
			return nil, fmt.Errorf("read Scheme library %q: %w", path, err)
		}
		source = append(source, contents...)
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
	program, err := resolvePath(programValue, false)
	if err != nil {
		return nil, fmt.Errorf("resolve Scheme program %q: %w", programValue, err)
	}
	contents, err := os.ReadFile(program)
	if err != nil {
		return nil, fmt.Errorf("read Scheme program %q: %w", program, err)
	}
	source = append(source, contents...)
	source = append(source, '\n')
	return source, nil
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

func emitGoldenCandidate(client http.Client, baseURL, goldenCase string, capture []byte) error {
	parts := strings.SplitN(goldenCase, "/", 2)
	response, err := client.Get(baseURL + "/candidate?app=" + parts[0])
	if err != nil {
		return fmt.Errorf("generate OTLP Scheme golden candidate: %w", err)
	}
	golden, readErr := io.ReadAll(response.Body)
	response.Body.Close()
	if readErr != nil {
		return fmt.Errorf("read OTLP Scheme golden candidate: %w", readErr)
	}
	if response.StatusCode != http.StatusOK {
		return fmt.Errorf("generate OTLP Scheme golden candidate: HTTP %d: %s", response.StatusCode, golden)
	}
	profile, err := implementationProfile(parts[0])
	if err != nil {
		return err
	}
	golden = append([]byte(fmt.Sprintf("(define-library (realworld detail %s %s)\n  (export expected-implementation-buckets)\n  (import (scheme base))\n  (begin\n", profile, parts[1])), golden...)
	golden = append(golden, []byte("  ))\n")...)
	root := os.Getenv("TEST_UNDECLARED_OUTPUTS_DIR")
	if root == "" {
		return errors.New("TEST_UNDECLARED_OUTPUTS_DIR is unavailable for golden candidate")
	}
	directory := filepath.Join(root, parts[0], parts[1])
	if err := os.MkdirAll(directory, 0o755); err != nil {
		return fmt.Errorf("create golden candidate output directory: %w", err)
	}
	capturePath := filepath.Join(directory, "capture.json")
	goldenPath := filepath.Join(directory, "golden.scm")
	if err := os.WriteFile(capturePath, capture, 0o644); err != nil {
		return fmt.Errorf("write raw candidate capture: %w", err)
	}
	if err := os.WriteFile(goldenPath, golden, 0o644); err != nil {
		return fmt.Errorf("write Scheme golden candidate: %w", err)
	}
	return nil
}

func implementationProfile(app string) (string, error) {
	switch app {
	case "aiohttp":
		return "python-aiohttp-auto-v0-65b0", nil
	case "django":
		return "python-django-auto-v0-65b0", nil
	default:
		return "", fmt.Errorf("unknown OTLP implementation profile for %q", app)
	}
}

func emitFailedCapture(goldenCase string, capture []byte) {
	root := os.Getenv("TEST_UNDECLARED_OUTPUTS_DIR")
	if root == "" {
		return
	}
	name := strings.NewReplacer("/", "-", "\\", "-").Replace(goldenCase)
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
