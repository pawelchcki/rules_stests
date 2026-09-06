package main

import (
	"os"
	"os/exec"
	"path/filepath"
	"reflect"
	"strings"
	"testing"
)

func TestLaunchArgsPreserveApplicationFlags(t *testing.T) {
	args := []string{"--runtime=python", "--instance=sample-otel", "--rootfs=app root", "--otel-rootfs=agent root", "--", "serve", "--runtime=app-option", "--port", "8123", "two words", ""}
	got, err := parseLaunchArgs(args)
	if err != nil {
		t.Fatal(err)
	}
	want := launchConfig{runtime: "python", instance: "sample-otel", rootfs: "app root", otelRootfs: "agent root", injection: injection{otelRootfs: "agent root"}, command: "serve", args: args[6:]}
	if !reflect.DeepEqual(got, want) {
		t.Fatalf("launch configuration = %#v, want %#v", got, want)
	}
}

func TestLaunchArgsRejectInvalidConfiguration(t *testing.T) {
	for _, args := range [][]string{
		{},
		{"--runtime=unknown", "--instance=sample", "--rootfs=root", "--", "serve"},
		{"--runtime=python", "--instance=../escape", "--rootfs=root", "--", "serve"},
		{"--runtime=python", "--instance=sample", "--", "serve"},
		{"--runtime=python", "--instance=sample", "--rootfs=root"},
		{"--runtime=python", "--instance=sample", "--rootfs=root", "--otel-rootfs=", "--", "serve"},
		{"--runtime=python", "--instance=sample", "--rootfs=root", "--otel-rootfs=one", "--otel-rootfs=two", "--", "serve"},
	} {
		if _, err := parseLaunchArgs(args); err == nil {
			t.Errorf("accepted invalid arguments %q", args)
		}
	}
}

func TestLaunchArgsPreserveGenericInjection(t *testing.T) {
	got, err := parseLaunchArgs([]string{
		"--runtime=ruby", "--instance=rails", "--rootfs=app", "--otel-rootfs=agent",
		"--env=RUBYOPT=-r{otel_rootfs}/activation.rb", "--env=EMPTY=",
		"--prepend-path=RUBYLIB=first", "--append-path=RUBYLIB=last",
		"--require={otel_rootfs}/activation.rb", "--require={otel_rootfs}/gems",
		"--", "server", "--binding", "127.0.0.1",
	})
	if err != nil {
		t.Fatal(err)
	}
	want := injection{
		otelRootfs:  "agent",
		environment: []environmentEdit{{key: "RUBYOPT", value: "-r{otel_rootfs}/activation.rb"}, {key: "EMPTY", value: ""}},
		prependPath: []environmentEdit{{key: "RUBYLIB", value: "first"}},
		appendPath:  []environmentEdit{{key: "RUBYLIB", value: "last"}},
		require:     []string{"{otel_rootfs}/activation.rb", "{otel_rootfs}/gems"},
	}
	if !reflect.DeepEqual(got.injection, want) {
		t.Fatalf("injection = %#v, want %#v", got.injection, want)
	}
}

// Run the real exec path in a child so replacing the process cannot terminate
// the test runner. The fixture exits with a nonzero code to check propagation.
func TestNativeLauncherExec(t *testing.T) {
	if os.Getenv("RULES_STESTS_LAUNCH_CHILD") == "1" {
		if err := run([]string{"--runtime=native", "--instance=sample", "--rootfs=" + os.Getenv("RULES_STESTS_APP_ROOT"), "--", "bin/app", "two words", "--port=8123", ""}); err != nil {
			t.Fatal(err)
		}
		t.Fatal("exec returned without replacing the process")
	}
	root := t.TempDir()
	if err := os.MkdirAll(filepath.Join(root, "bin"), 0o755); err != nil {
		t.Fatal(err)
	}
	script := "#!/bin/sh\nprintf '%s\\n' \"$APP_STATE_DIR\" \"$PWD\" \"$OTEL_SERVICE_NAME\" \"$#\" \"$1\" \"$2\" \"$3\"\nexit 23\n"
	if err := os.WriteFile(filepath.Join(root, "bin", "app"), []byte(script), 0o755); err != nil {
		t.Fatal(err)
	}
	for _, serviceName := range []string{"", "caller-service"} {
		t.Run("service-name="+serviceName, func(t *testing.T) {
			t.Setenv("APP_STATE_DIR", "")
			t.Setenv("TEST_TMPDIR", t.TempDir())
			t.Setenv("RULES_STESTS_LAUNCH_CHILD", "1")
			t.Setenv("RULES_STESTS_APP_ROOT", root)
			t.Setenv("OTEL_SERVICE_NAME", serviceName)
			environment := os.Environ()
			if serviceName == "" {
				for i, entry := range environment {
					if strings.HasPrefix(entry, "OTEL_SERVICE_NAME=") {
						environment = append(environment[:i], environment[i+1:]...)
						break
					}
				}
				serviceName = "sample"
			}
			binary, err := os.Executable()
			if err != nil {
				t.Fatal(err)
			}
			command := exec.Command(binary, "-test.run=^TestNativeLauncherExec$")
			command.Env = environment
			output, err := command.CombinedOutput()
			if exit, ok := err.(*exec.ExitError); !ok || exit.ExitCode() != 23 {
				t.Fatalf("launcher result = %v; output: %s", err, output)
			}
			state := filepath.Join(os.Getenv("TEST_TMPDIR"), "rules_stests", "sample", "state")
			want := strings.Join([]string{state, state, serviceName, "3", "two words", "--port=8123", "", ""}, "\n")
			if string(output) != want {
				t.Fatalf("output = %q, want %q", output, want)
			}
		})
	}
}

func TestStateSeedDoesNotModifyRootfsOrExistingState(t *testing.T) {
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
	if err := prepareAppState(root, "sample"); err != nil {
		t.Fatal(err)
	}
	database := filepath.Join(state, "realworld.sqlite3")
	if got, err := os.ReadFile(database); err != nil || string(got) != "seed" {
		t.Fatalf("seeded state = %q, %v", got, err)
	}
	if err := os.WriteFile(database, []byte("changed"), 0o600); err != nil {
		t.Fatal(err)
	}
	if err := prepareAppState(root, "sample"); err != nil {
		t.Fatal(err)
	}
	for path, want := range map[string]string{seed: "seed", database: "changed"} {
		if got, err := os.ReadFile(path); err != nil || string(got) != want {
			t.Errorf("%s = %q, %v; want %q", path, got, err, want)
		}
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

	// The rootfs is read-only, so the server pidfile must land in the state
	// directory rather than the application root's tmp/pids.
	plainArgs := strings.Join(plain.arguments, " ")
	if !strings.Contains(plainArgs, "--pid "+filepath.Join(state, "server.pid")) {
		t.Fatalf("server invocation did not redirect its pidfile: %s", plainArgs)
	}
	chosen, err := rubyAppExecution(root, injection{}, "", "rails", "server", []string{"--pid", "/chosen.pid"}, inherited)
	if err != nil {
		t.Fatal(err)
	}
	if strings.Count(strings.Join(chosen.arguments, " "), "--pid") != 1 {
		t.Fatalf("a caller-chosen pidfile was overridden: %v", chosen.arguments)
	}
	migrate, err := rubyAppExecution(root, injection{}, "", "rails", "db:migrate", nil, inherited)
	if err != nil {
		t.Fatal(err)
	}
	if strings.Contains(strings.Join(migrate.arguments, " "), "--pid") {
		t.Fatalf("a non-server command was given a pidfile: %v", migrate.arguments)
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
