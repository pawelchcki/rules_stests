package main

import (
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strconv"
	"strings"
)

func main() {
	serviceSuffix := flag.String("service-suffix", "", "suffix of the rules_itest service label")
	flag.Parse()
	if *serviceSuffix == "" {
		fatal(errors.New("--service-suffix is required"))
	}

	port, err := assignedPort(*serviceSuffix)
	if err != nil {
		fatal(err)
	}
	runner, err := resolvePath(os.Getenv("HURL_RUNNER"), false)
	if err != nil {
		fatal(fmt.Errorf("resolve HURL_RUNNER: %w", err))
	}
	layout, err := resolvePath(os.Getenv("HURL_LAYOUT"), true)
	if err != nil {
		fatal(fmt.Errorf("resolve HURL_LAYOUT: %w", err))
	}
	specValues := strings.Fields(os.Getenv("HURL_SPECS"))
	if len(specValues) == 0 {
		fatal(errors.New("HURL_SPECS is empty"))
	}
	specs := make([]string, 0, len(specValues))
	for _, value := range specValues {
		spec, resolveErr := resolvePath(value, false)
		if resolveErr != nil {
			fatal(fmt.Errorf("resolve Hurl spec %q: %w", value, resolveErr))
		}
		specs = append(specs, spec)
	}

	args := []string{
		"hurl",
		"hurl",
		layout,
		"--test",
		"--jobs",
		"1",
		"--error-format",
		"long",
		"--variable",
		fmt.Sprintf("host=http://127.0.0.1:%d", port),
		"--variable",
		"uid=rules_stests",
	}
	args = append(args, specs...)
	command := exec.Command(runner, args...)
	command.Env = append(os.Environ(), "NO_COLOR=1")
	command.Stdout = os.Stdout
	command.Stderr = os.Stderr
	if err := command.Run(); err != nil {
		fatal(fmt.Errorf("RealWorld Hurl suite failed: %w", err))
	}
	fmt.Printf("RealWorld Hurl suite passed against %s on port %d (%d files)\n", *serviceSuffix, port, len(specs))
}

func fatal(err error) {
	fmt.Fprintln(os.Stderr, "hurl_test_driver:", err)
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
	if runfiles := os.Getenv("RUNFILES_DIR"); runfiles != "" {
		candidates = append(candidates, filepath.Join(runfiles, value))
	}
	if testSrcdir := os.Getenv("TEST_SRCDIR"); testSrcdir != "" {
		candidates = append(candidates, filepath.Join(testSrcdir, value))
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
