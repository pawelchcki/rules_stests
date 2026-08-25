package main

import (
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

func main() {
	baseURL := flag.String("base-url", "", "API origin to test, for example http://127.0.0.1:8000")
	host := flag.String("host", "127.0.0.1", "API host when --port is used")
	portFlag := flag.Int("port", 0, "API port (alternative to --base-url)")
	serviceSuffix := flag.String("service-suffix", "", "rules_itest service label suffix used to discover an assigned port")
	otelSinkSuffix := flag.String("otel-sink-suffix", "", "OTLP sink service suffix whose decoded trace, metric, and log dump must become non-empty")
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

	rootfsValue := os.Getenv("HURL_ROOTFS")
	if rootfsValue == "" {
		rootfsValue = "bazel/itest/hurl_rootfs"
	}
	rootfs, err := resolvePath(rootfsValue, true)
	if err != nil {
		fatal(fmt.Errorf("resolve HURL_ROOTFS: %w", err))
	}

	specValues := flag.Args()
	if len(specValues) == 0 {
		specValues = strings.Fields(os.Getenv("HURL_SPECS"))
	}
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
		if err := requireExportedTelemetry(*otelSinkSuffix); err != nil {
			fatal(err)
		}
	}
	fmt.Printf("RealWorld Hurl suite passed against %s (%d files, %d jobs)\n", endpoint, len(specs), *jobs)
}

func requireExportedTelemetry(serviceSuffix string) error {
	port, err := assignedPort(serviceSuffix)
	if err != nil {
		return fmt.Errorf("locate OTLP sink: %w", err)
	}
	url := fmt.Sprintf("http://127.0.0.1:%d/dump", port)
	deadline := time.Now().Add(time.Minute)
	for {
		requestTimeout := time.Until(deadline)
		if requestTimeout <= 0 {
			return fmt.Errorf("OTLP sink at %s did not receive traces, metrics, and logs containing service.name", url)
		}
		client := http.Client{Timeout: requestTimeout}
		response, requestErr := client.Get(url)
		if requestErr == nil {
			contents, readErr := io.ReadAll(response.Body)
			response.Body.Close()
			if readErr == nil && response.StatusCode == http.StatusOK {
				var records []struct {
					Signal  string          `json:"signal"`
					Payload json.RawMessage `json:"payload"`
				}
				if json.Unmarshal(contents, &records) == nil {
					seen := map[string]bool{}
					for _, record := range records {
						if strings.Contains(string(record.Payload), `"service.name"`) {
							seen[record.Signal] = true
						}
					}
					if seen["traces"] && seen["metrics"] && seen["logs"] {
						fmt.Printf("Verified OTLP traces, metrics, and logs with resource metadata in %s\n", url)
						return nil
					}
				}
			}
		}
		if time.Now().After(deadline) {
			return fmt.Errorf("OTLP sink at %s did not receive traces, metrics, and logs containing service.name", url)
		}
		time.Sleep(100 * time.Millisecond)
	}
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
