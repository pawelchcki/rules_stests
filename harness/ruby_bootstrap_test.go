package main

import (
	"crypto/sha256"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"testing"
)

func TestDatadogRubyBootstrap(t *testing.T) {
	root, err := resolveDirectory(os.Getenv("RAILS_ROOTFS"))
	if err != nil {
		t.Fatal(err)
	}
	payload, err := resolveDirectory(os.Getenv("DATADOG_RUBY_ROOTFS"))
	if err != nil {
		t.Fatal(err)
	}
	t.Setenv("APP_STATE_DIR", t.TempDir())
	app := filepath.Join(root, "opt/app/src")
	hashes := map[string][32]byte{}
	for _, name := range []string{"Gemfile", "Gemfile.lock"} {
		data, err := os.ReadFile(filepath.Join(app, name))
		if err != nil {
			t.Fatal(err)
		}
		hashes[name] = sha256.Sum256(data)
	}
	run := func(payload, code string) ([]byte, error) {
		config := injection{instrumentationRootfs: payload, environment: []environmentEdit{{key: "RUBYOPT", value: "-r{instrumentation_rootfs}/datadog-ruby/activation.rb"}, {key: "RULES_STESTS_DATADOG_RUBY_ROOT", value: "{instrumentation_rootfs}/datadog-ruby"}}}
		config, _, err = resolveInjection(config)
		if err != nil {
			return nil, err
		}
		execution, err := rubyAppExecution(root, config, "", "bootstrap", "runner", nil, append(os.Environ(), "BUNDLE_FROZEN=true", "DD_TRACE_ENABLED=false", "DD_INSTRUMENTATION_TELEMETRY_ENABLED=false", "DD_REMOTE_CONFIGURATION_ENABLED=false"))
		if err != nil {
			return nil, err
		}
		args := append(execution.arguments[1:4], "-e", code)
		command := exec.Command(execution.loader, args...)
		command.Env = execution.environment
		command.Dir = app
		return command.CombinedOutput()
	}
	t.Run("frozen-idempotent-early", func(t *testing.T) {
		code := fmt.Sprintf(`raise "late activation" if Rails.application&.initialized?
RulesStestsDatadog.activate!; RulesStestsDatadog.activate!
raise "wrong tracer" unless Gem.loaded_specs.fetch("datadog").version.to_s == "2.42.0"
raise "duplicate load paths" unless $LOAD_PATH.uniq == $LOAD_PATH
require %q
raise "missing early Rack instrumentation" unless Rails.application.middleware.any? { |m| m.klass.name == "Datadog::Tracing::Contrib::Rack::TraceMiddleware" }
puts "bootstrap verified"`, filepath.Join(app, "config/environment"))
		out, err := run(payload, code)
		if err != nil || !strings.Contains(string(out), "bootstrap verified") {
			t.Fatalf("%v: %s", err, out)
		}
	})
	for _, mutation := range []struct {
		name, want string
		change     func(string) error
	}{
		{"abi", "ABI mismatch", func(root string) error {
			return os.WriteFile(filepath.Join(root, "abi.json"), []byte(`{"ruby_version":"0.0.0","arch":"wrong"}`), 0644)
		}},
		{"dependency", "missing Datadog dependency", func(root string) error {
			paths, _ := filepath.Glob(filepath.Join(root, "specifications/datadog-ruby_core_source-*.gemspec"))
			if len(paths) != 1 {
				return fmt.Errorf("expected locked dependency")
			}
			return os.Remove(paths[0])
		}},
		{"incompatible-dependency", "incompatible or missing Datadog dependency", func(root string) error {
			path := filepath.Join(root, "activation.rb")
			data, err := os.ReadFile(path)
			if err != nil {
				return err
			}
			code := `Gem.loaded_specs["datadog-ruby_core_source"] = Gem::Specification.new { |s| s.name = "datadog-ruby_core_source"; s.version = "0.0.1" }
`
			return os.WriteFile(path, []byte(strings.Replace(string(data), "RulesStestsDatadog.activate!", code+"RulesStestsDatadog.activate!", 1)), 0644)
		}},
		{"native-extension", "missing native extensions", func(root string) error {
			paths, _ := filepath.Glob(filepath.Join(root, "extensions/*/*/datadog-*/gem.build_complete"))
			if len(paths) != 1 {
				return fmt.Errorf("expected native build marker, got %v", paths)
			}
			return os.Remove(paths[0])
		}},
	} {
		t.Run(mutation.name, func(t *testing.T) {
			copy := t.TempDir()
			if out, err := exec.Command("cp", "-aL", filepath.Join(payload, "datadog-ruby"), copy).CombinedOutput(); err != nil {
				t.Fatalf("copy: %v %s", err, out)
			}
			if out, err := exec.Command("chmod", "-R", "u+w", copy).CombinedOutput(); err != nil {
				t.Fatalf("chmod: %v %s", err, out)
			}
			if err := mutation.change(filepath.Join(copy, "datadog-ruby")); err != nil {
				t.Fatal(err)
			}
			out, err := run(copy, `raise "unexpected successful activation"`)
			if err == nil || !strings.Contains(string(out), mutation.want) {
				t.Fatalf("expected %q rejection, got %v: %s", mutation.want, err, out)
			}
		})
	}
	for name, want := range hashes {
		data, err := os.ReadFile(filepath.Join(app, name))
		if err != nil || sha256.Sum256(data) != want {
			t.Fatalf("application %s changed", name)
		}
	}
}
