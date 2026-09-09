package main

import (
	"bytes"
	"crypto/sha256"
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"io"
	"net"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"reflect"
	"sort"
	"strconv"
	"strings"
	"syscall"
	"time"
)

type result struct {
	SchemaVersion int               `json:"schemaVersion"`
	Application   string            `json:"application"`
	Captures      map[string]string `json:"captureSha256"`
	RejectionLogs map[string]string `json:"rejectionLogSha256,omitempty"`
	Observations  []observation     `json:"observations"`
}

var client = &http.Client{Timeout: 5 * time.Second}

func main() {
	app := flag.String("app", "", "fixture application")
	launcher := flag.String("launcher", "", "app launcher runfile")
	expected := flag.String("expected", "", "reviewed outcome JSON runfile")
	discover := flag.Bool("discover", false, "record discoveries without comparing reviewed outcomes")
	compare := flag.Bool("compare", false, "render a comparison of result JSON files given as arguments")
	launchJSON := flag.String("launch-args", "[]", "JSON array of launcher arguments")
	flag.Parse()
	if *compare {
		if err := compareResults(flag.Args(), os.Stdout); err != nil {
			fail(err)
		}
		return
	}
	var launchArgs []string
	if err := json.Unmarshal([]byte(*launchJSON), &launchArgs); err != nil {
		fail(err)
	}
	if *app == "" || *launcher == "" || len(launchArgs) == 0 {
		fail(fmt.Errorf("--app, --launcher, and --launch-args are required"))
	}
	if err := run(*app, resolve(*launcher), resolve(*expected), *discover, launchArgs); err != nil {
		fail(err)
	}
}

func run(app, launcher, expected string, discover bool, args []string) error {
	endpoint, err := sinkEndpoint()
	if err != nil {
		return err
	}
	out := os.Getenv("TEST_UNDECLARED_OUTPUTS_DIR")
	if out == "" {
		return fmt.Errorf("TEST_UNDECLARED_OUTPUTS_DIR is required to retain evidence")
	}
	if err := os.MkdirAll(out, 0755); err != nil {
		return err
	}
	r := result{SchemaVersion: 1, Application: app, Captures: map[string]string{}, RejectionLogs: map[string]string{}}
	collect := func(e experiment) (capture, error) {
		data, err := collect(app, launcher, args, endpoint, out, e)
		if err != nil {
			return capture{}, fmt.Errorf("%s/%s: %w", app, e.Name, err)
		}
		r.Captures[e.Name] = fmt.Sprintf("%x", sha256.Sum256(data))
		if err := os.WriteFile(filepath.Join(out, e.Name+".capture.json"), data, 0644); err != nil {
			return capture{}, err
		}
		return decodeCapture(data)
	}
	baseline, err := collect(experiment{Name: "baseline"})
	if err != nil {
		return err
	}
	if len(baseline.Spans) == 0 {
		return fmt.Errorf("baseline exported no spans; experiments cannot be interpreted")
	}
	for _, e := range experiments {
		control := baseline
		if definition, ok := experimentControls[e.Name]; ok {
			control, err = collect(definition)
			if err != nil {
				return err
			}
			if e.Name == "sampler-arg" && len(control.Spans) == 0 {
				return fmt.Errorf("traceidratio=1 control exported no spans")
			}
		}
		changed, err := collect(e)
		var o observation
		if err != nil {
			var startup *startupExit
			var workload *workloadFailure
			if !errors.As(err, &startup) && !errors.As(err, &workload) {
				return err
			}
			if startup != nil {
				var exit *exec.ExitError
				if !errors.As(startup.cause, &exit) || exit.ExitCode() != 1 {
					return err
				}
			}
			log, readErr := os.ReadFile(filepath.Join(out, e.Name+".app.log"))
			if readErr != nil {
				return readErr
			}
			var known bool
			o, known = configurationRejection(app, e, string(log))
			if !known {
				return err
			}
			if (workload != nil) != (o.Status == "workload_rejected") {
				return err
			}
			r.RejectionLogs[e.Name] = fmt.Sprintf("%x", sha256.Sum256(log))
		} else {
			o = evaluate(e, control, changed)
		}
		r.Observations = append(r.Observations, o)
		fmt.Printf("%s/%s: %s: %s\n", app, e.Name, o.Status, o.Detail)
	}
	data, err := json.MarshalIndent(r, "", "  ")
	if err != nil {
		return err
	}
	if err := os.WriteFile(filepath.Join(out, "external-features.json"), append(data, '\n'), 0644); err != nil {
		return err
	}
	if discover {
		return nil
	}
	data, err = os.ReadFile(expected)
	if err != nil {
		return err
	}
	var golden map[string]map[string]string
	if err := json.Unmarshal(data, &golden); err != nil {
		return err
	}
	var changes []string
	for _, o := range r.Observations {
		if golden[app][o.Case] != o.signature() {
			changes = append(changes, fmt.Sprintf("%s: expected %q, observed %q (%s)", o.Case, golden[app][o.Case], o.signature(), o.Detail))
		}
	}
	if len(golden[app]) != len(r.Observations) {
		changes = append(changes, "reviewed case set differs from executed case set")
	}
	if len(changes) > 0 {
		return fmt.Errorf("external behavior changed; review capture evidence:\n%s", strings.Join(changes, "\n"))
	}
	return nil
}

func collect(app, launcher string, args []string, sink, out string, e experiment) ([]byte, error) {
	if _, err := request("POST", sink+"/reset", nil); err != nil {
		return nil, err
	}
	listener, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		return nil, err
	}
	port := listener.Addr().(*net.TCPAddr).Port
	listener.Close()
	env := map[string]string{
		"OTEL_SERVICE_NAME":                   "external-probe",
		"OTEL_EXPORTER_OTLP_ENDPOINT":         sink,
		"OTEL_EXPORTER_OTLP_TRACES_ENDPOINT":  sink + "/v1/traces",
		"OTEL_EXPORTER_OTLP_METRICS_ENDPOINT": sink + "/v1/metrics",
		"OTEL_EXPORTER_OTLP_LOGS_ENDPOINT":    sink + "/v1/logs",
		"OTEL_EXPORTER_OTLP_PROTOCOL":         "http/protobuf",
		"OTEL_EXPORTER_OTLP_COMPRESSION":      "none",
		"OTEL_TRACES_EXPORTER":                "otlp", "OTEL_METRICS_EXPORTER": "otlp", "OTEL_LOGS_EXPORTER": "otlp",
		"OTEL_BSP_SCHEDULE_DELAY": "100", "OTEL_BLRP_SCHEDULE_DELAY": "100", "OTEL_METRIC_EXPORT_INTERVAL": "500",
		"OTEL_PYTHON_LOGGING_AUTO_INSTRUMENTATION_ENABLED": "true",
		"OTEL_RUBY_ENABLED_INSTRUMENTATIONS":               "rack,rails,action_pack,active_record",
	}
	if app == "rails" {
		env["OTEL_METRICS_EXPORTER"] = "none"
	}
	if app == "gin" {
		env["OTEL_LOGS_EXPORTER"] = "none"
		env["OTEL_RESOURCE_ATTRIBUTES"] = "process.owner=nonroot"
	}
	for k, v := range e.Env {
		env[k] = v
	}
	var launchArgs []string
	for _, arg := range args {
		if arg == "--" {
			launchArgs = append(launchArgs, "--instance=external-"+e.Name)
			keys := make([]string, 0, len(env))
			for key := range env {
				keys = append(keys, key)
			}
			sort.Strings(keys)
			for _, k := range keys {
				launchArgs = append(launchArgs, "--env="+k+"="+env[k])
			}
		}
		launchArgs = append(launchArgs, strings.ReplaceAll(arg, "{PORT}", strconv.Itoa(port)))
	}
	log, err := os.Create(filepath.Join(out, e.Name+".app.log"))
	if err != nil {
		return nil, err
	}
	defer log.Close()
	cmd := exec.Command(launcher, launchArgs...)
	// Ambient SDK configuration must not change either side of the experiment.
	for _, entry := range os.Environ() {
		if !strings.HasPrefix(entry, "OTEL_") && !strings.HasPrefix(entry, "APP_STATE_DIR=") {
			cmd.Env = append(cmd.Env, entry)
		}
	}
	cmd.Stdout, cmd.Stderr = log, log
	cmd.SysProcAttr = &syscall.SysProcAttr{Setpgid: true}
	if err := cmd.Start(); err != nil {
		return nil, err
	}
	done := make(chan error, 1)
	go func() { done <- cmd.Wait() }()
	stopped := false
	defer func() {
		if !stopped {
			syscall.Kill(-cmd.Process.Pid, syscall.SIGKILL)
			<-done
		}
	}()
	base := fmt.Sprintf("http://127.0.0.1:%d", port)
	ready := false
	for deadline := time.Now().Add(30 * time.Second); time.Now().Before(deadline); {
		select {
		case err := <-done:
			stopped = true
			return nil, &startupExit{err}
		default:
		}
		if response, err := client.Get(base + "/api/tags"); err == nil {
			io.Copy(io.Discard, response.Body)
			response.Body.Close()
			if response.StatusCode == 500 {
				return nil, &workloadFailure{response.StatusCode}
			}
			if response.StatusCode == 200 {
				ready = true
				break
			}
		}
		time.Sleep(100 * time.Millisecond)
	}
	if !ready {
		return nil, fmt.Errorf("application readiness timed out")
	}
	if err := workload(base, e.Name); err != nil {
		return nil, err
	}
	// Several complete 500 ms reader periods give both captures measurements.
	// The process must remain alive throughout the observation window.
	select {
	case err := <-done:
		stopped = true
		return nil, fmt.Errorf("application exited during workload: %v", err)
	case <-time.After(2500 * time.Millisecond):
	}
	syscall.Kill(-cmd.Process.Pid, syscall.SIGTERM)
	select {
	case <-done:
		stopped = true
	case <-time.After(time.Second):
		// Gin's instrumentation intercepts SIGTERM and flushes the SDK but
		// leaves the HTTP server running. Lifecycle shutdown is not a feature
		// claimed by these experiments; stop this owned process after its grace.
		if err := syscall.Kill(-cmd.Process.Pid, syscall.SIGKILL); err != nil {
			return nil, err
		}
		<-done
		stopped = true
	}
	return request("GET", sink+"/dump", nil)
}

type startupExit struct{ cause error }

type workloadFailure struct{ status int }

func (e *workloadFailure) Error() string {
	return fmt.Sprintf("application health request returned HTTP %d", e.status)
}

func (e *startupExit) Error() string {
	return fmt.Sprintf("application exited before workload: %v", e.cause)
}

// Only observed SDK configuration diagnostics qualify. Arbitrary crashes,
// missing images and failed health checks stay hard errors, even in discovery.
func configurationRejection(app string, e experiment, log string) (observation, bool) {
	if app == "django" && e.Name == "propagation-none" && strings.Contains(log, "opentelemetry/context/__init__.py") && strings.Contains(log, "AttributeError: 'NoneType' object has no attribute 'get'") {
		return observation{Case: e.Name, Features: e.Features, Status: "workload_rejected", Detail: "HTTP 500: OpenTelemetry context is None with OTEL_PROPAGATORS=none"}, true
	}
	if app != "rails" {
		return observation{}, false
	}
	message := ""
	source := "opentelemetry/sdk/trace/span_limits.rb"
	switch e.Name {
	case "span-length", "attribute-length":
		message = "attribute_length_limit must not be less than 32"
	case "events":
		message = "event_count_limit must be positive"
	case "log-length":
		message = "attribute_length_limit must not be less than 32"
		source = "opentelemetry/sdk/logs/log_record_limits.rb"
	}
	if message == "" || !strings.Contains(log, source) || !strings.Contains(log, message+" (ArgumentError)") {
		return observation{}, false
	}
	return observation{Case: e.Name, Features: e.Features, Status: "startup_rejected", Detail: message}, true
}

func workload(base, caseName string) error {
	for i := 0; i < 4; i++ {
		req, err := http.NewRequest("GET", base+"/api/tags", nil)
		if err != nil {
			return err
		}
		req.Header.Set("User-Agent", "external-feature-probe-long-user-agent")
		req.Header.Set("X-Probe-Feature", "visible")
		req.Header.Set("traceparent", fmt.Sprintf("00-%032x-00f067aa0ba902b7-01", i+1))
		resp, err := client.Do(req)
		if err != nil {
			return err
		}
		io.Copy(io.Discard, resp.Body)
		resp.Body.Close()
		if resp.StatusCode != 200 {
			return fmt.Errorf("tags returned %d", resp.StatusCode)
		}
	}
	// Duplicate registration emits exception events in Django's SQLite spans
	// and request error logs without adding instrumentation to any application.
	body := []byte(`{"user":{"username":"external_probe","email":"external_probe@test.com","password":"password123"}}`)
	for i := 0; i < 3; i++ {
		req, err := http.NewRequest("POST", base+"/api/users", bytes.NewReader(body))
		if err != nil {
			return err
		}
		req.Header.Set("Content-Type", "application/json")
		resp, err := client.Do(req)
		if err != nil {
			return err
		}
		io.Copy(io.Discard, resp.Body)
		resp.Body.Close()
		want := 201
		if i > 0 {
			want = 409
		}
		if resp.StatusCode != want {
			return fmt.Errorf("registration %d returned %d, expected %d", i, resp.StatusCode, want)
		}
	}
	if caseName == "log-batch" || caseName == "log-batch-control" {
		// A bounded concurrent burst gives the log processor an opportunity
		// to batch error records, independent of individual password-hash time.
		results := make(chan error, 8)
		for i := 0; i < 8; i++ {
			go func() {
				resp, err := client.Post(base+"/api/users", "application/json", bytes.NewReader(body))
				if err == nil {
					io.Copy(io.Discard, resp.Body)
					resp.Body.Close()
					if resp.StatusCode != 409 {
						err = fmt.Errorf("log batch workload returned HTTP %d", resp.StatusCode)
					}
				}
				results <- err
			}()
		}
		var first error
		for i := 0; i < 8; i++ {
			if err := <-results; first == nil {
				first = err
			}
		}
		if first != nil {
			return first
		}
	}
	return nil
}
func request(method, url string, body []byte) ([]byte, error) {
	req, err := http.NewRequest(method, url, bytes.NewReader(body))
	if err != nil {
		return nil, err
	}
	resp, err := client.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()
	data, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}
	if resp.StatusCode != 200 {
		return nil, fmt.Errorf("%s %s: HTTP %d: %s", method, url, resp.StatusCode, data)
	}
	return data, nil
}
func sinkEndpoint() (string, error) {
	var ports map[string]json.RawMessage
	if err := json.Unmarshal([]byte(os.Getenv("ASSIGNED_PORTS")), &ports); err != nil {
		return "", err
	}
	for label, raw := range ports {
		if strings.HasSuffix(label, "//harness:otel_sink_service") {
			var p int
			if err := json.Unmarshal(raw, &p); err != nil {
				var s string
				if err := json.Unmarshal(raw, &s); err != nil {
					return "", err
				}
				p, err = strconv.Atoi(s)
				if err != nil {
					return "", err
				}
			}
			return fmt.Sprintf("http://127.0.0.1:%d", p), nil
		}
	}
	return "", fmt.Errorf("OTLP sink missing from ASSIGNED_PORTS")
}
func resolve(path string) string {
	if _, err := os.Stat(path); err == nil {
		return path
	}
	for _, key := range []string{"RUNFILES_DIR", "TEST_SRCDIR"} {
		p := filepath.Join(os.Getenv(key), path)
		if _, err := os.Stat(p); err == nil {
			return p
		}
	}
	return path
}
func fail(err error) { fmt.Fprintln(os.Stderr, err); os.Exit(1) }

func compareResults(paths []string, out io.Writer) error {
	var results []result
	apps := map[string]bool{}
	for _, path := range paths {
		data, err := os.ReadFile(path)
		if err != nil {
			return err
		}
		var r result
		if err := json.Unmarshal(data, &r); err != nil {
			return err
		}
		if r.SchemaVersion != 1 {
			return fmt.Errorf("unsupported result schema")
		}
		if apps[r.Application] {
			return fmt.Errorf("duplicate application %q", r.Application)
		}
		apps[r.Application] = true
		if err := verifyResult(r, filepath.Dir(path)); err != nil {
			return fmt.Errorf("%s: %w", path, err)
		}
		results = append(results, r)
	}
	if len(results) < 2 {
		return fmt.Errorf("comparison requires at least two application results")
	}
	sort.Slice(results, func(i, j int) bool { return results[i].Application < results[j].Application })
	fmt.Fprint(out, "| Experiment |")
	for _, r := range results {
		fmt.Fprintf(out, " %s |", r.Application)
	}
	fmt.Fprint(out, " Difference |\n| --- |")
	for range results {
		fmt.Fprint(out, " --- |")
	}
	fmt.Fprintln(out, " --- |")
	features := map[string]bool{}
	exercised := map[string]bool{}
	passed := map[string]bool{}
	for _, e := range experiments {
		fmt.Fprintf(out, "| %s |", e.Name)
		statuses := map[string]bool{}
		for _, r := range results {
			status := "missing"
			for _, o := range r.Observations {
				if o.Case == e.Name {
					status = o.Status
					for _, f := range o.Features {
						features[f] = true
						if status != "not_exercised" {
							exercised[f] = true
						}
						if status == "pass" {
							passed[f] = true
						}
					}
				}
			}
			statuses[status] = true
			fmt.Fprintf(out, " %s |", status)
		}
		difference := ""
		if statuses["pass"] && (statuses["gap"] || statuses["startup_rejected"] || statuses["workload_rejected"]) {
			difference = "observed discrepancy"
		}
		fmt.Fprintf(out, " %s |\n", difference)
	}
	fmt.Fprintf(out, "\n%d distinct additional features; %d exercised; %d passed in at least one fixture.\n", len(features), len(exercised), len(passed))
	return nil
}

// Recompute the comparison from its retained inputs. A stale edited result or
// a missing capture must not turn into either a passing feature or a gap.
func verifyResult(r result, dir string) error {
	read := func(name, suffix, digest string) ([]byte, error) {
		data, err := os.ReadFile(filepath.Join(dir, name+suffix))
		if err != nil {
			return nil, err
		}
		if fmt.Sprintf("%x", sha256.Sum256(data)) != digest {
			return nil, fmt.Errorf("evidence digest mismatch for %s", name)
		}
		return data, nil
	}
	load := func(name string) (capture, error) {
		data, err := read(name, ".capture.json", r.Captures[name])
		if err != nil {
			return capture{}, err
		}
		return decodeCapture(data)
	}
	baseline, err := load("baseline")
	if err != nil {
		return err
	}
	if len(baseline.Spans) == 0 {
		return fmt.Errorf("baseline has no spans")
	}
	if len(r.Observations) != len(experiments) {
		return fmt.Errorf("incomplete experiment set")
	}
	if len(r.Captures)+len(r.RejectionLogs) != len(experiments)+1+len(experimentControls) {
		return fmt.Errorf("unexpected evidence set")
	}
	for i, e := range experiments {
		control := baseline
		if definition, ok := experimentControls[e.Name]; ok {
			control, err = load(definition.Name)
			if err != nil {
				return err
			}
			if e.Name == "sampler-arg" && len(control.Spans) == 0 {
				return fmt.Errorf("traceidratio=1 control has no spans")
			}
		}
		var want observation
		if hash, ok := r.RejectionLogs[e.Name]; ok {
			log, err := read(e.Name, ".app.log", hash)
			if err != nil {
				return err
			}
			var known bool
			want, known = configurationRejection(r.Application, e, string(log))
			if !known {
				return fmt.Errorf("unrecognized startup failure for %s", e.Name)
			}
		} else {
			c, err := load(e.Name)
			if err != nil {
				return err
			}
			want = evaluate(e, control, c)
		}
		if !reflect.DeepEqual(r.Observations[i], want) {
			return fmt.Errorf("observation disagrees with evidence for %s", e.Name)
		}
	}
	return nil
}
