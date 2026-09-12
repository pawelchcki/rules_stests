package main

import (
	_ "embed"
	"errors"
	"flag"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"strings"
	"syscall"
)

//go:embed probes/python.py
var pythonProbes string

var pythonBootstrap = pythonBootstrapSetup + pythonProbes + pythonBootstrapEntrypoint

const pythonBootstrapSetup = `
import asyncio
import os
import runpy
import socketserver
import sys

socketserver.TCPServer.allow_reuse_port = True
original_create_server = asyncio.BaseEventLoop.create_server

async def create_server_with_reuse_port(self, *args, **kwargs):
    if kwargs.get("reuse_port") is None:
        kwargs["reuse_port"] = True
    return await original_create_server(self, *args, **kwargs)

asyncio.BaseEventLoop.create_server = create_server_with_reuse_port
# Datadog's supported aiohttp server integration requires trace_app; its
# automatic patcher only covers the client. Activate the server middleware
# from the injection environment, before the application freezes its router.
if os.environ.get("RULES_STESTS_DATADOG_AIOHTTP_ENABLED") == "true" and os.environ.get("DD_TRACE_ENABLED", "true").lower() != "false":
    from aiohttp import web
    from ddtrace.contrib.aiohttp import trace_app

    original_run_app = web.run_app

    def traced_run_app(app, *args, **kwargs):
        if asyncio.iscoroutine(app):
            original_app = app

            async def traced_application():
                resolved_app = await original_app
                trace_app(resolved_app, service=os.environ["DD_SERVICE"])
                return resolved_app

            app = traced_application()
        else:
            trace_app(app, service=os.environ["DD_SERVICE"])
        return original_run_app(app, *args, **kwargs)

    web.run_app = traced_run_app
`

const pythonBootstrapEntrypoint = `
entrypoint = sys.argv[1]
sys.argv = sys.argv[1:]
runpy.run_path(entrypoint, run_name="__main__")
`

// launchConfig is independent of OCI acquisition and extraction. Its rootfs
// inputs are already materialized Bazel directories.
type launchConfig struct {
	runtime               string
	instance              string
	rootfs                string
	otelRootfs            string
	instrumentationRootfs string
	command               string
	args                  []string
	injection             injection
}

func main() {
	if err := run(os.Args[1:]); err != nil {
		fmt.Fprintln(os.Stderr, "app_launcher:", err)
		os.Exit(1)
	}
}

func parseLaunchArgs(args []string) (launchConfig, error) {
	var config launchConfig
	flags := flag.NewFlagSet("app_launcher", flag.ContinueOnError)
	flags.SetOutput(io.Discard)
	flags.StringVar(&config.runtime, "runtime", "", "python, ruby or native")
	flags.StringVar(&config.instance, "instance", "", "service instance name")
	flags.StringVar(&config.rootfs, "rootfs", "", "materialized application directory")
	flags.Func("otel-rootfs", "optional instrumentation directory", func(value string) error {
		if value == "" || config.otelRootfs != "" {
			return errors.New("--otel-rootfs requires a non-empty value and may be specified only once")
		}
		config.otelRootfs = value
		return nil
	})
	flags.Func("instrumentation-rootfs", "optional protocol-neutral instrumentation directory", func(value string) error {
		if value == "" || config.instrumentationRootfs != "" {
			return errors.New("--instrumentation-rootfs requires a non-empty value and may be specified only once")
		}
		config.instrumentationRootfs = value
		return nil
	})
	var injectionArgs []string
	for _, name := range []string{"env", "prepend-path", "append-path", "require"} {
		flags.Func(name, "runtime injection option", func(value string) error {
			injectionArgs = append(injectionArgs, "--"+name+"="+value)
			return nil
		})
	}
	if err := flags.Parse(args); err != nil {
		return config, err
	}
	if config.runtime != "python" && config.runtime != "ruby" && config.runtime != "native" {
		return config, fmt.Errorf("unsupported runtime %q: expected python, ruby or native", config.runtime)
	}
	if !validInstance(config.instance) {
		return config, fmt.Errorf("unsafe instance name %q", config.instance)
	}
	if config.rootfs == "" || len(flags.Args()) == 0 || flags.Arg(0) == "" {
		return config, errors.New("usage: app_launcher --runtime=<python|ruby|native> --instance=<name> --rootfs=<directory> [--otel-rootfs=<directory> | --instrumentation-rootfs=<directory>] -- <command> [arguments...]")
	}
	if config.otelRootfs != "" {
		injectionArgs = append(injectionArgs, "--otel-rootfs="+config.otelRootfs)
	}
	if config.instrumentationRootfs != "" {
		injectionArgs = append(injectionArgs, "--instrumentation-rootfs="+config.instrumentationRootfs)
	}
	parsedInjection, _, err := parseAppArgs(injectionArgs)
	if err != nil {
		return config, err
	}
	config.injection = parsedInjection
	config.command = flags.Arg(0)
	config.args = flags.Args()[1:]
	return config, nil
}

func run(args []string) error {
	config, err := parseLaunchArgs(args)
	if err != nil {
		return err
	}
	switch config.runtime {
	case "python":
		return runApp(config.injection, config.instance, config.rootfs, config.command, config.args)
	case "ruby":
		return runRubyApp(config.injection, config.instance, config.rootfs, config.command, config.args)
	default:
		return runAppExec(config.injection, config.instance, config.rootfs, config.command, config.args)
	}
}

type environmentEdit struct {
	key   string
	value string
}

type injection struct {
	otelRootfs            string
	instrumentationRootfs string
	environment           []environmentEdit
	prependPath           []environmentEdit
	appendPath            []environmentEdit
	require               []string
}

func parseAppArgs(args []string) (injection, []string, error) {
	var result injection
	for index, arg := range args {
		if arg == "--" {
			return validateInjection(result, args[index+1:])
		}
		if !strings.HasPrefix(arg, "--") {
			return validateInjection(result, args[index:])
		}
		name, value, ok := strings.Cut(arg, "=")
		if !ok || value == "" {
			return injection{}, nil, fmt.Errorf("injection option %q requires a non-empty value after =", name)
		}
		switch name {
		case "--otel-rootfs":
			if result.otelRootfs != "" {
				return injection{}, nil, errors.New("--otel-rootfs may be specified only once")
			}
			result.otelRootfs = value
		case "--instrumentation-rootfs":
			if result.instrumentationRootfs != "" {
				return injection{}, nil, errors.New("--instrumentation-rootfs may be specified only once")
			}
			result.instrumentationRootfs = value
		case "--env", "--prepend-path", "--append-path":
			key, editValue, found := strings.Cut(value, "=")
			if !found || key == "" {
				return injection{}, nil, fmt.Errorf("%s requires KEY=VALUE", name)
			}
			edit := environmentEdit{key: key, value: editValue}
			switch name {
			case "--env":
				result.environment = append(result.environment, edit)
			case "--prepend-path":
				result.prependPath = append(result.prependPath, edit)
			case "--append-path":
				result.appendPath = append(result.appendPath, edit)
			}
		case "--require":
			result.require = append(result.require, value)
		default:
			return injection{}, nil, fmt.Errorf("unknown injection option %q", name)
		}
	}
	return validateInjection(result, nil)
}

func validateInjection(value injection, positionals []string) (injection, []string, error) {
	if value.otelRootfs != "" && value.instrumentationRootfs != "" {
		return injection{}, nil, errors.New("--otel-rootfs and --instrumentation-rootfs are mutually exclusive")
	}
	values := append([]string{}, value.require...)
	for _, edits := range [][]environmentEdit{value.environment, value.prependPath, value.appendPath} {
		for _, edit := range edits {
			values = append(values, edit.value)
		}
	}
	for _, candidate := range values {
		if value.otelRootfs == "" && strings.Contains(candidate, "{otel_rootfs}") {
			return injection{}, nil, errors.New("{otel_rootfs} used without --otel-rootfs")
		}
		if value.instrumentationRootfs == "" && strings.Contains(candidate, "{instrumentation_rootfs}") {
			return injection{}, nil, errors.New("{instrumentation_rootfs} used without --instrumentation-rootfs")
		}
	}
	return value, positionals, nil
}

func resolveInjection(value injection) (injection, string, error) {
	rootArg, placeholder := value.otelRootfs, "{otel_rootfs}"
	if value.instrumentationRootfs != "" {
		rootArg, placeholder = value.instrumentationRootfs, "{instrumentation_rootfs}"
	}
	if rootArg == "" {
		return value, "", nil
	}
	root, err := resolveDirectory(rootArg)
	if err != nil {
		return injection{}, "", fmt.Errorf("resolve instrumentation rootfs: %w", err)
	}
	replace := func(input string) string { return strings.ReplaceAll(input, placeholder, root) }
	for _, edits := range [][]environmentEdit{value.environment, value.prependPath, value.appendPath} {
		for index := range edits {
			edits[index].value = replace(edits[index].value)
		}
	}
	for index := range value.require {
		value.require[index] = replace(value.require[index])
	}
	// Only the legacy option activates OTel defaults. Neutral instrumentation
	// obtains its entire exporter configuration from its declared injection.
	if value.instrumentationRootfs != "" {
		return value, "", nil
	}
	return value, root, nil
}

func runRubyApp(injection injection, instance, rootArg, command string, args []string) error {
	if !validInstance(instance) {
		return fmt.Errorf("unsafe instance name %q", instance)
	}
	root, err := resolveDirectory(rootArg)
	if err != nil {
		return err
	}
	if err := prepareAppState(root, instance); err != nil {
		return err
	}
	injection, otelRoot, err := resolveInjection(injection)
	if err != nil {
		return err
	}
	return execRubyApp(root, injection, otelRoot, instance, command, args)
}

func stringSliceContainsAny(values []string, wanted ...string) bool {
	for _, value := range values {
		name, _, _ := strings.Cut(value, "=")
		for _, candidate := range wanted {
			if name == candidate {
				return true
			}
		}
	}
	return false
}

type rubyExecution struct {
	loader      string
	arguments   []string
	environment []string
}

func rubyAppExecution(root string, injection injection, otelRoot, instance, command string, args []string, inherited []string) (rubyExecution, error) {
	appRoot := filepath.Join(root, "opt", "app")
	loader := filepath.Join(root, "lib64", "ld-linux-x86-64.so.2")
	ruby := filepath.Join(appRoot, "ruby", "bin", "ruby")
	rails := filepath.Join(appRoot, "src", "bin", "rails")
	for label, path := range map[string]string{"dynamic loader": loader, "Ruby runtime": ruby, "Rails launcher": rails} {
		if info, err := os.Stat(path); err != nil || info.IsDir() {
			if err == nil {
				err = errors.New("is a directory")
			}
			return rubyExecution{}, fmt.Errorf("inspect bundled %s: %w", label, err)
		}
	}
	prismLibraries, err := filepath.Glob(filepath.Join(appRoot, "bundle", "ruby", "3.3.0", "gems", "prism-*", "lib"))
	if err != nil || len(prismLibraries) != 1 {
		return rubyExecution{}, fmt.Errorf("Rails rootfs must contain exactly one bundled Prism library, got %d", len(prismLibraries))
	}

	blocked := map[string]bool{
		"BUNDLE_GEMFILE": true, "BUNDLE_PATH": true, "DATABASE_PATH": true, "GEM_HOME": true, "GEM_PATH": true,
		"LD_LIBRARY_PATH": true, "OTEL_RUBY_ADDITIONAL_GEM_PATH": true, "REALWORLD_BUNDLE_ROOT": true, "RUBYLIB": true, "RUBYOPT": true,
	}
	environment := make([]string, 0, len(inherited)+10)
	present := make(map[string]bool, len(inherited))
	for _, entry := range inherited {
		key, _, _ := strings.Cut(entry, "=")
		if !blocked[key] {
			present[key] = true
			environment = append(environment, entry)
		}
	}
	// The image declares RAILS_ENV=production, but nothing here goes through a
	// container runtime, so that declaration never reaches the process. Without
	// it Rails boots in development against a database seeded and stamped for
	// production, and its error handling differs from what the profile pins.
	environment = appendDefaultEnvironment(environment, present, "RAILS_ENV", "production")
	state := os.Getenv("APP_STATE_DIR")
	if state == "" {
		return rubyExecution{}, errors.New("APP_STATE_DIR is required after state preparation")
	}
	environment = append(environment,
		"BUNDLE_GEMFILE="+filepath.Join(appRoot, "src", "Gemfile"),
		"BUNDLE_PATH="+filepath.Join(appRoot, "bundle"),
		"DATABASE_PATH="+filepath.Join(state, "realworld.sqlite3"),
		"GEM_HOME="+filepath.Join(appRoot, "ruby", "lib", "ruby", "gems", "3.3.0"),
		"GEM_PATH="+filepath.Join(appRoot, "ruby", "lib", "ruby", "gems", "3.3.0"),
		"REALWORLD_BUNDLE_ROOT="+appRoot,
		"RUBYLIB="+strings.Join([]string{prismLibraries[0], filepath.Join(appRoot, "ruby", "lib", "ruby", "3.3.0"), filepath.Join(appRoot, "ruby", "lib", "ruby", "3.3.0", "x86_64-linux")}, ":"),
	)
	libraryPath := strings.Join([]string{
		filepath.Join(root, "lib", "x86_64-linux-gnu"),
		filepath.Join(root, "usr", "lib", "x86_64-linux-gnu"),
		filepath.Join(appRoot, "ruby", "lib"),
	}, ":")
	environment = append(environment, "LD_LIBRARY_PATH="+libraryPath)
	environment, err = applyInjection(environment, injection, otelRoot, instance, false)
	if err != nil {
		return rubyExecution{}, err
	}
	arguments := []string{loader, "--library-path", libraryPath, ruby, rails, command}
	arguments = append(arguments, args...)
	// The rootfs is read-only, but `rails server` writes its pidfile under the
	// application root at tmp/pids/server.pid. Redirect it into the writable
	// state directory unless the caller chose a location.
	if command == "server" && !stringSliceContainsAny(args, "--pid", "-P") {
		arguments = append(arguments, "--pid", filepath.Join(state, "server.pid"))
	}
	return rubyExecution{loader: loader, arguments: arguments, environment: environment}, nil
}

func execRubyApp(root string, injection injection, otelRoot, instance, command string, args []string) error {
	execution, err := rubyAppExecution(root, injection, otelRoot, instance, command, args, os.Environ())
	if err != nil {
		return err
	}
	if otelRoot != "" {
		fmt.Fprintf(os.Stderr, "app_launcher: activating instrumentation for %s from %s\n", instance, otelRoot)
	}
	if err := syscall.Exec(execution.loader, execution.arguments, execution.environment); err != nil {
		return fmt.Errorf("execute Rails app with bundled Ruby: %w", err)
	}
	return nil
}

func runApp(injection injection, instance, rootArg, command string, args []string) error {
	if !validInstance(instance) {
		return fmt.Errorf("unsafe instance name %q", instance)
	}
	root, err := resolveDirectory(rootArg)
	if err != nil {
		return err
	}
	if err := prepareAppState(root, instance); err != nil {
		return err
	}
	injection, otelRoot, err := resolveInjection(injection)
	if err != nil {
		return err
	}
	return execPythonApp(root, injection, otelRoot, instance, command, args)
}

// runAppExec launches a self-contained binary from an app image. Unlike
// runApp it interposes no language runtime: the image supplies a static
// executable, and the per-instance state directory becomes its working
// directory so relative database paths stay inside the instance.
func runAppExec(injection injection, instance, rootArg, relative string, args []string) error {
	if !validInstance(instance) {
		return fmt.Errorf("unsafe instance name %q", instance)
	}
	root, err := resolveDirectory(rootArg)
	if err != nil {
		return err
	}
	if err := prepareAppState(root, instance); err != nil {
		return err
	}
	binary, err := safePath(root, relative)
	if err != nil {
		return fmt.Errorf("resolve app binary: %w", err)
	}
	if info, err := os.Stat(binary); err != nil {
		return fmt.Errorf("inspect app binary %s: %w", relative, err)
	} else if info.IsDir() {
		return fmt.Errorf("app binary %s is a directory", relative)
	}
	state := os.Getenv("APP_STATE_DIR")
	if err := os.Chdir(state); err != nil {
		return fmt.Errorf("enter app state directory: %w", err)
	}

	injection, otelRoot, err := resolveInjection(injection)
	if err != nil {
		return err
	}
	environment, err := applyInjection(os.Environ(), injection, otelRoot, instance, false)
	if err != nil {
		return err
	}
	if injection.instrumentationRootfs == "" {
		environment = applyExecDefaults(environment, instance)
	}
	if otelRoot != "" {
		fmt.Fprintf(os.Stderr, "app_launcher: activating instrumentation for %s from %s\n", instance, otelRoot)
	}
	if err := syscall.Exec(binary, append([]string{binary}, args...), environment); err != nil {
		return fmt.Errorf("execute app binary %s: %w", relative, err)
	}
	return nil
}

func applyExecDefaults(environment []string, instance string) []string {
	present := make(map[string]bool, len(environment))
	for _, entry := range environment {
		key, _, _ := strings.Cut(entry, "=")
		present[key] = true
	}
	return appendDefaultEnvironment(environment, present, "OTEL_SERVICE_NAME", instance)
}

func validInstance(value string) bool {
	if value == "" {
		return false
	}
	for _, r := range value {
		if (r < 'a' || r > 'z') && (r < '0' || r > '9') && r != '-' && r != '_' {
			return false
		}
	}
	return true
}

type pythonExecution struct {
	loader      string
	arguments   []string
	environment []string
}

func pythonAppExecution(root string, injection injection, otelRoot, instance, command string, args []string, inherited []string) (pythonExecution, error) {
	appRoot := filepath.Join(root, "opt", "app")
	loader := filepath.Join(root, "lib64", "ld-linux-x86-64.so.2")
	python := filepath.Join(appRoot, "python", "bin", "python3")
	entrypoint := filepath.Join(appRoot, "entrypoint.py")
	libraryPath := strings.Join([]string{
		filepath.Join(root, "lib", "x86_64-linux-gnu"),
		filepath.Join(appRoot, "python", "lib"),
	}, ":")
	pythonPath := []string{
		filepath.Join(appRoot, "site-packages"),
		filepath.Join(appRoot, "src"),
	}

	environment := make([]string, 0, len(inherited)+7)
	for _, entry := range inherited {
		key, _, _ := strings.Cut(entry, "=")
		if key != "PYTHONHOME" && key != "PYTHONPATH" && key != "REALWORLD_BUNDLE_ROOT" {
			environment = append(environment, entry)
		}
	}
	environment = append(environment,
		"PYTHONHOME="+filepath.Join(appRoot, "python"),
		"PYTHONPATH="+strings.Join(pythonPath, ":"),
		"REALWORLD_BUNDLE_ROOT="+appRoot,
	)
	django := false
	if _, err := os.Stat(filepath.Join(appRoot, "src", "manage.py")); err == nil {
		django = true
	}
	var err error
	environment, err = applyInjection(environment, injection, otelRoot, instance, django)
	if err != nil {
		return pythonExecution{}, err
	}
	arguments := []string{loader, "--library-path", libraryPath, python, "-c", pythonBootstrap, entrypoint, command}
	arguments = append(arguments, args...)
	return pythonExecution{loader: loader, arguments: arguments, environment: environment}, nil
}

func execPythonApp(root string, injection injection, otelRoot, instance, command string, args []string) error {
	execution, err := pythonAppExecution(root, injection, otelRoot, instance, command, args, os.Environ())
	if err != nil {
		return err
	}
	if otelRoot != "" {
		fmt.Fprintf(os.Stderr, "app_launcher: activating instrumentation for %s from %s\n", instance, otelRoot)
	}
	if err := syscall.Exec(execution.loader, execution.arguments, execution.environment); err != nil {
		return fmt.Errorf("execute app with bundled glibc: %w", err)
	}
	return nil
}

func applyInjection(environment []string, value injection, otelRoot, instance string, django bool) ([]string, error) {
	set := func(key, value string) {
		prefix := key + "="
		for index, entry := range environment {
			if strings.HasPrefix(entry, prefix) {
				environment[index] = prefix + value
				return
			}
		}
		environment = append(environment, prefix+value)
	}
	get := func(key string) string {
		prefix := key + "="
		for index := len(environment) - 1; index >= 0; index-- {
			if strings.HasPrefix(environment[index], prefix) {
				return strings.TrimPrefix(environment[index], prefix)
			}
		}
		return ""
	}
	for _, edit := range value.prependPath {
		current := get(edit.key)
		if current == "" {
			set(edit.key, edit.value)
		} else {
			set(edit.key, edit.value+":"+current)
		}
	}
	for _, edit := range value.appendPath {
		current := get(edit.key)
		if current == "" {
			set(edit.key, edit.value)
		} else {
			set(edit.key, current+":"+edit.value)
		}
	}
	for _, edit := range value.environment {
		set(edit.key, edit.value)
	}
	if otelRoot != "" {
		present := make(map[string]bool, len(environment))
		for _, entry := range environment {
			key, _, _ := strings.Cut(entry, "=")
			present[key] = true
		}
		environment = appendDefaultEnvironment(environment, present, "OTEL_SERVICE_NAME", instance)
		environment = appendDefaultEnvironment(environment, present, "OTEL_TRACES_EXPORTER", "console")
		environment = appendDefaultEnvironment(environment, present, "OTEL_METRICS_EXPORTER", "none")
		environment = appendDefaultEnvironment(environment, present, "OTEL_LOGS_EXPORTER", "none")
	}
	// sitecustomize executes before entrypoint.py, so every Django launcher
	// prepares settings and the writable database before starting Python.
	if django {
		present := make(map[string]bool, len(environment))
		for _, entry := range environment {
			key, _, _ := strings.Cut(entry, "=")
			present[key] = true
		}
		environment = appendDefaultEnvironment(environment, present, "DEBUG", "True")
		environment = appendDefaultEnvironment(environment, present, "DJANGO_SETTINGS_MODULE", "config.settings")
		database := filepath.Join(os.Getenv("APP_STATE_DIR"), "realworld.sqlite3")
		environment = appendDefaultEnvironment(environment, present, "DATABASE_URL", "file:"+database)
	}
	for _, path := range value.require {
		if _, err := os.Stat(path); err != nil {
			return nil, fmt.Errorf("required injection path %s: %w", path, err)
		}
	}
	return environment, nil
}

func appendDefaultEnvironment(environment []string, present map[string]bool, key, value string) []string {
	if present[key] {
		return environment
	}
	return append(environment, key+"="+value)
}

func prepareAppState(root, instance string) error {
	state := os.Getenv("APP_STATE_DIR")
	if state == "" {
		testTmp := os.Getenv("TEST_TMPDIR")
		if testTmp == "" {
			return errors.New("TEST_TMPDIR or APP_STATE_DIR is required")
		}
		state = filepath.Join(testTmp, "rules_stests", instance, "state")
		if err := os.Setenv("APP_STATE_DIR", state); err != nil {
			return fmt.Errorf("set APP_STATE_DIR: %w", err)
		}
	}
	if err := os.MkdirAll(state, 0o755); err != nil {
		return fmt.Errorf("create app state: %w", err)
	}
	seed := filepath.Join(root, "opt", "app", "seed", "realworld.sqlite3")
	if _, err := os.Stat(seed); errors.Is(err, os.ErrNotExist) {
		return nil
	} else if err != nil {
		return fmt.Errorf("inspect app seed: %w", err)
	}
	database := filepath.Join(state, "realworld.sqlite3")
	if _, err := os.Stat(database); err == nil {
		return nil
	} else if !errors.Is(err, os.ErrNotExist) {
		return fmt.Errorf("inspect app database: %w", err)
	}
	method, err := cloneOrCopyFile(seed, database)
	if err != nil {
		return fmt.Errorf("materialize app database seed: %w", err)
	}
	fmt.Fprintf(os.Stderr, "app_launcher: materialized writable state via %s: %s\n", method, database)
	return nil
}

func cloneOrCopyFile(source, destination string) (string, error) {
	input, err := os.Open(source)
	if err != nil {
		return "", err
	}
	defer input.Close()
	temporary, err := os.CreateTemp(filepath.Dir(destination), ".realworld.sqlite3-")
	if err != nil {
		return "", err
	}
	temporaryPath := temporary.Name()
	committed := false
	defer func() {
		temporary.Close()
		if !committed {
			os.Remove(temporaryPath)
		}
	}()

	const ficlone = 0x40049409
	_, _, cloneErr := syscall.Syscall(syscall.SYS_IOCTL, temporary.Fd(), uintptr(ficlone), input.Fd())
	method := "reflink"
	if cloneErr != 0 {
		method = "copy fallback"
		if err := temporary.Truncate(0); err != nil {
			return "", err
		}
		if _, err := temporary.Seek(0, io.SeekStart); err != nil {
			return "", err
		}
		if _, err := input.Seek(0, io.SeekStart); err != nil {
			return "", err
		}
		if _, err := io.Copy(temporary, input); err != nil {
			return "", err
		}
	}
	if err := temporary.Chmod(0o600); err != nil {
		return "", err
	}
	if err := temporary.Close(); err != nil {
		return "", err
	}
	if err := os.Rename(temporaryPath, destination); err != nil {
		return "", err
	}
	committed = true
	return method, nil
}
