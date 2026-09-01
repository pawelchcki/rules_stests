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

func TestRubyActivationHookRejectsAbsentAndAmbiguousHooks(t *testing.T) {
	root := t.TempDir()
	if _, _, err := rubyActivationHook(root); err == nil || !strings.Contains(err.Error(), "got 0") {
		t.Fatalf("absent hook error = %v", err)
	}
	for _, directory := range []string{"one", "two"} {
		path := filepath.Join(root, directory)
		if err := os.MkdirAll(filepath.Join(path, "gems"), 0o755); err != nil {
			t.Fatal(err)
		}
		if err := os.WriteFile(filepath.Join(path, "activation.rb"), nil, 0o444); err != nil {
			t.Fatal(err)
		}
	}
	if _, _, err := rubyActivationHook(root); err == nil || !strings.Contains(err.Error(), "got 2") {
		t.Fatalf("ambiguous hook error = %v", err)
	}
}

func TestRubyActivationHookReturnsPayloadRoot(t *testing.T) {
	root := t.TempDir()
	payload := filepath.Join(root, "otel-auto-instrumentation-ruby")
	if err := os.MkdirAll(filepath.Join(payload, "gems"), 0o755); err != nil {
		t.Fatal(err)
	}
	hook := filepath.Join(payload, "activation.rb")
	if err := os.WriteFile(hook, nil, 0o444); err != nil {
		t.Fatal(err)
	}
	gotHook, gotPayload, err := rubyActivationHook(root)
	if err != nil {
		t.Fatal(err)
	}
	if gotHook != hook || gotPayload != payload {
		t.Fatalf("hook/payload = %q, %q", gotHook, gotPayload)
	}
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
	plain, err := rubyAppExecution(root, "", "rails", "server", []string{"--port", "1"}, inherited)
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
	instrumented, err := rubyAppExecution(root, otel, "rails-otel", "server", nil, inherited)
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
