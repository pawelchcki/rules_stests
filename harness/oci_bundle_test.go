package main

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestRemoveDanglingSymlinksPreservesEmptyDirectoryTarget(t *testing.T) {
	root := t.TempDir()
	lockDirectory := filepath.Join(root, "run", "lock")
	if err := os.MkdirAll(lockDirectory, 0o755); err != nil {
		t.Fatal(err)
	}
	varDirectory := filepath.Join(root, "var")
	if err := os.MkdirAll(varDirectory, 0o755); err != nil {
		t.Fatal(err)
	}
	lockLink := filepath.Join(varDirectory, "lock")
	if err := os.Symlink("../run/lock", lockLink); err != nil {
		t.Fatal(err)
	}

	if err := removeDanglingSymlinks(root); err != nil {
		t.Fatal(err)
	}
	info, err := os.Lstat(lockLink)
	if err != nil {
		t.Fatal(err)
	}
	if info.Mode()&os.ModeSymlink == 0 {
		t.Fatalf("%s is no longer a symlink", lockLink)
	}
	if _, err := os.Stat(filepath.Join(lockDirectory, treeArtifactDirectoryMarker)); err != nil {
		t.Fatalf("empty symlink target has no tree-artifact marker: %v", err)
	}
}

func TestRemoveDanglingSymlinksRemovesMissingTarget(t *testing.T) {
	root := t.TempDir()
	link := filepath.Join(root, "missing")
	if err := os.Symlink("does-not-exist", link); err != nil {
		t.Fatal(err)
	}

	if err := removeDanglingSymlinks(root); err != nil {
		t.Fatal(err)
	}
	if _, err := os.Lstat(link); !os.IsNotExist(err) {
		t.Fatalf("dangling symlink still exists: %v", err)
	}
}

func TestRemoveDanglingSymlinksPreservesReadOnlyEmptyTarget(t *testing.T) {
	root := t.TempDir()
	target := filepath.Join(root, "target")
	if err := os.Mkdir(target, 0o755); err != nil {
		t.Fatal(err)
	}
	if err := os.Chmod(target, 0o555); err != nil {
		t.Fatal(err)
	}
	link := filepath.Join(root, "link")
	if err := os.Symlink("target", link); err != nil {
		t.Fatal(err)
	}

	if err := removeDanglingSymlinks(root); err != nil {
		t.Fatal(err)
	}
	if _, err := os.Stat(filepath.Join(target, treeArtifactDirectoryMarker)); err != nil {
		t.Fatalf("read-only symlink target has no tree-artifact marker: %v", err)
	}
	info, err := os.Stat(target)
	if err != nil {
		t.Fatal(err)
	}
	if got := info.Mode().Perm(); got != 0o555 {
		t.Fatalf("target mode = %o, want 555", got)
	}
	if err := os.Chmod(target, 0o755); err != nil {
		t.Fatalf("make target removable: %v", err)
	}
}

func TestParseAppArgsSeparatesOptionsAndPositionals(t *testing.T) {
	parsed, positionals, err := parseAppArgs([]string{
		"--otel-rootfs=agent", "--env=RUBYOPT=-r{otel_rootfs}/activation.rb",
		"instance", "rootfs", "serve", "--port", "$${PORT}",
	})
	if err != nil {
		t.Fatal(err)
	}
	if parsed.otelRootfs != "agent" || len(parsed.environment) != 1 {
		t.Fatalf("injection = %#v", parsed)
	}
	if got := strings.Join(positionals, "|"); got != "instance|rootfs|serve|--port|$${PORT}" {
		t.Fatalf("positionals = %q", got)
	}

	_, positionals, err = parseAppArgs([]string{"--", "instance", "rootfs", "--command"})
	if err != nil || strings.Join(positionals, "|") != "instance|rootfs|--command" {
		t.Fatalf("-- positionals = %q, %v", positionals, err)
	}
}

func TestParseAppArgsRejectsPlaceholderWithoutRootfs(t *testing.T) {
	if _, _, err := parseAppArgs([]string{"--require={otel_rootfs}/hook", "app", "root", "serve"}); err == nil || !strings.Contains(err.Error(), "without --otel-rootfs") {
		t.Fatalf("placeholder error = %v", err)
	}
}

func TestApplyInjectionRequiresExistingPath(t *testing.T) {
	_, err := applyInjection(nil, injection{require: []string{filepath.Join(t.TempDir(), "missing")}}, "", "app", false)
	if err == nil || !strings.Contains(err.Error(), "required injection path") {
		t.Fatalf("missing requirement error = %v", err)
	}
}

func TestPythonExecutionAppliesPathInjectionAfterIsolation(t *testing.T) {
	root := makePythonRoot(t)
	otel := t.TempDir()
	hook := filepath.Join(otel, "auto", "sitecustomize.py")
	if err := os.MkdirAll(filepath.Dir(hook), 0o755); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(hook, nil, 0o444); err != nil {
		t.Fatal(err)
	}
	parsed, _, err := parseAppArgs([]string{
		"--otel-rootfs=" + otel,
		"--prepend-path=PYTHONPATH={otel_rootfs}/auto",
		"--append-path=PYTHONPATH={otel_rootfs}/tail",
		"--require={otel_rootfs}/auto/sitecustomize.py",
	})
	if err != nil {
		t.Fatal(err)
	}
	parsed, resolved, err := resolveInjection(parsed)
	if err != nil {
		t.Fatal(err)
	}
	execution, err := pythonAppExecution(root, parsed, resolved, "python", "serve", nil, []string{"PYTHONPATH=/host", "KEEP=value"})
	if err != nil {
		t.Fatal(err)
	}
	environment := strings.Join(execution.environment, "\n")
	want := "PYTHONPATH=" + filepath.Join(otel, "auto") + ":" + filepath.Join(root, "opt", "app", "site-packages") + ":" + filepath.Join(root, "opt", "app", "src") + ":" + filepath.Join(otel, "tail")
	if !strings.Contains(environment, want) || strings.Contains(environment, "/host") {
		t.Fatalf("environment =\n%s\nwant %s", environment, want)
	}
}

func TestInjectionEnvironmentOverridesBlockedKey(t *testing.T) {
	environment, err := applyInjection([]string{"KEEP=value"}, injection{environment: []environmentEdit{{key: "RUBYOPT", value: "-rgood"}}}, "", "ruby", false)
	if err != nil || !strings.Contains(strings.Join(environment, "\n"), "RUBYOPT=-rgood") {
		t.Fatalf("environment = %q, %v", environment, err)
	}
}

func TestOtelDefaultsRequireRootfs(t *testing.T) {
	plain, err := applyInjection(nil, injection{}, "", "plain", false)
	if err != nil || strings.Contains(strings.Join(plain, "\n"), "OTEL_SERVICE_NAME") {
		t.Fatalf("plain defaults = %q, %v", plain, err)
	}
	instrumented, err := applyInjection(nil, injection{}, t.TempDir(), "otel", false)
	if err != nil || !strings.Contains(strings.Join(instrumented, "\n"), "OTEL_SERVICE_NAME=otel") {
		t.Fatalf("instrumented defaults = %q, %v", instrumented, err)
	}
}

func TestExecServiceNameDefaultPreservesExplicitValue(t *testing.T) {
	defaulted := strings.Join(applyExecDefaults([]string{"KEEP=value"}, "gin-otel"), "\n")
	if !strings.Contains(defaulted, "OTEL_SERVICE_NAME=gin-otel") {
		t.Fatalf("defaulted environment = %q", defaulted)
	}
	explicit := strings.Join(applyExecDefaults([]string{"OTEL_SERVICE_NAME=custom"}, "gin-otel"), "\n")
	if explicit != "OTEL_SERVICE_NAME=custom" {
		t.Fatalf("explicit environment = %q", explicit)
	}
}

func TestRetryableBindFailureIsNarrow(t *testing.T) {
	if !retryableBindFailure([]byte("listen tcp 127.0.0.1:8080: bind: address already in use")) {
		t.Fatal("Gin bind collision was not retryable")
	}
	for _, output := range [][]byte{
		[]byte("database migration failed"),
		[]byte("permission denied while binding"),
		[]byte("address already in use"),
	} {
		if retryableBindFailure(output) {
			t.Fatalf("unrelated startup failure was retryable: %q", output)
		}
	}
}

func makePythonRoot(t *testing.T) string {
	t.Helper()
	root := t.TempDir()
	app := filepath.Join(root, "opt", "app")
	for _, path := range []string{
		filepath.Join(root, "lib64", "ld-linux-x86-64.so.2"),
		filepath.Join(app, "python", "bin", "python3"),
		filepath.Join(app, "entrypoint.py"),
	} {
		if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
			t.Fatal(err)
		}
		if err := os.WriteFile(path, nil, 0o555); err != nil {
			t.Fatal(err)
		}
	}
	return root
}

func TestRubyExecutionIsolatesApplicationAndAgentEnvironment(t *testing.T) {
	root := t.TempDir()
	app := filepath.Join(root, "opt", "app")
	for _, path := range []string{
		filepath.Join(root, "lib64", "ld-linux-x86-64.so.2"),
		filepath.Join(app, "ruby", "bin", "ruby"),
		filepath.Join(app, "src", "bin", "rails"),
	} {
		if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
			t.Fatal(err)
		}
		if err := os.WriteFile(path, nil, 0o555); err != nil {
			t.Fatal(err)
		}
	}
	if err := os.MkdirAll(filepath.Join(app, "bundle", "ruby", "3.3.0", "gems", "prism-1.9.0", "lib"), 0o755); err != nil {
		t.Fatal(err)
	}
	state := t.TempDir()
	t.Setenv("APP_STATE_DIR", state)
	inherited := []string{"RUBYOPT=-rbad", "GEM_HOME=/host", "BUNDLE_GEMFILE=/host/Gemfile", "KEEP=value"}
	plain, err := rubyAppExecution(root, injection{}, "", "rails", "server", []string{"--port", "1"}, inherited)
	if err != nil {
		t.Fatal(err)
	}
	joined := strings.Join(plain.environment, "\n")
	if strings.Contains(joined, "-rbad") || strings.Contains(joined, "/host") || !strings.Contains(joined, "KEEP=value") {
		t.Fatalf("plain environment was not isolated:\n%s", joined)
	}
	if strings.Contains(joined, "OTEL_RUBY_ADDITIONAL_GEM_PATH") {
		t.Fatal("plain execution activated the agent")
	}

	otel := t.TempDir()
	payload := filepath.Join(otel, "otel-auto-instrumentation-ruby")
	if err := os.MkdirAll(filepath.Join(payload, "gems"), 0o755); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(payload, "activation.rb"), nil, 0o444); err != nil {
		t.Fatal(err)
	}
	parsed, _, err := parseAppArgs([]string{
		"--otel-rootfs=" + otel,
		"--env=OTEL_RUBY_ADDITIONAL_GEM_PATH={otel_rootfs}/otel-auto-instrumentation-ruby",
		"--env=RUBYOPT=-r{otel_rootfs}/otel-auto-instrumentation-ruby/activation.rb",
		"--require={otel_rootfs}/otel-auto-instrumentation-ruby/activation.rb",
		"--require={otel_rootfs}/otel-auto-instrumentation-ruby/gems",
	})
	if err != nil {
		t.Fatal(err)
	}
	parsed, resolved, err := resolveInjection(parsed)
	if err != nil {
		t.Fatal(err)
	}
	instrumented, err := rubyAppExecution(root, parsed, resolved, "rails-otel", "server", nil, inherited)
	if err != nil {
		t.Fatal(err)
	}
	joined = strings.Join(instrumented.environment, "\n")
	if !strings.Contains(joined, "RUBYOPT=-r"+filepath.Join(payload, "activation.rb")) ||
		!strings.Contains(joined, "OTEL_RUBY_ADDITIONAL_GEM_PATH="+payload) ||
		!strings.Contains(joined, "OTEL_METRICS_EXPORTER=none") {
		t.Fatalf("instrumented environment is incomplete:\n%s", joined)
	}
}

func TestPrepareAppStateClonesSeedOnce(t *testing.T) {
	root := t.TempDir()
	seed := filepath.Join(root, "opt", "app", "seed", "realworld.sqlite3")
	if err := os.MkdirAll(filepath.Dir(seed), 0o755); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(seed, []byte("seed"), 0o444); err != nil {
		t.Fatal(err)
	}
	state := t.TempDir()
	t.Setenv("APP_STATE_DIR", state)
	if err := prepareAppState(root, "ruby"); err != nil {
		t.Fatal(err)
	}
	database := filepath.Join(state, "realworld.sqlite3")
	if contents, err := os.ReadFile(database); err != nil || string(contents) != "seed" {
		t.Fatalf("clone = %q, %v", contents, err)
	}
	if err := os.WriteFile(database, []byte("changed"), 0o600); err != nil {
		t.Fatal(err)
	}
	if err := prepareAppState(root, "ruby"); err != nil {
		t.Fatal(err)
	}
	if contents, _ := os.ReadFile(database); string(contents) != "changed" {
		t.Fatalf("existing state was overwritten: %q", contents)
	}
}
