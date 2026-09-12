"""Public RealWorld application and telemetry test-suite macros."""

load("//bazel:oci_images.lock.bzl", "RUBY_IMAGES_PUBLISHED")
load("//rules:corpus_service.bzl", "corpus_service")
load("//rules:hurl_test.bzl", "REALWORLD_BASE_HURL_CASES")
load("//rules:realworld_service_tests.bzl", "realworld_service_tests")

_SINK = Label("//harness:otel_sink_service")

_SERVER_ARGS = ["serve", "--host", "127.0.0.1", "--port", "$${PORT}"]

REALWORLD_APPS = {
    "aiohttp": struct(
        runtime = "python",
        rootfs = Label("//harness:aiohttp_rootfs"),
        command = _SERVER_ARGS,
        so_reuseport_aware = True,
        expected_start_duration = "3s",
        manual = False,
    ),
    "django": struct(
        runtime = "python",
        rootfs = Label("//harness:django_rootfs"),
        command = _SERVER_ARGS,
        so_reuseport_aware = True,
        expected_start_duration = "3s",
        manual = False,
    ),
    "rails": struct(
        runtime = "ruby",
        rootfs = Label("//harness:rails_rootfs"),
        command = ["server", "--binding", "127.0.0.1", "--port", "$${PORT}"],
        so_reuseport_aware = False,
        expected_start_duration = "4s",
        manual = not RUBY_IMAGES_PUBLISHED,
    ),
    "gin": struct(
        runtime = "exec",
        rootfs = Label("//harness:gin_rootfs"),
        binary = "opt/app/bin/realworld-gin",
        otel_binary = "opt/app/bin/realworld-gin-otel",
        command = _SERVER_ARGS,
        so_reuseport_aware = True,
        expected_start_duration = "3s",
        manual = False,
    ),
}

def otlp_env(traces = True, metrics = True, logs = True, per_signal_endpoints = False, extra = {}):
    """Returns consistent OTLP exporter environment variables."""
    endpoint = "http://127.0.0.1:$${%s}" % str(_SINK)
    env = {
        "OTEL_EXPORTER_OTLP_PROTOCOL": "http/protobuf",
        "OTEL_TRACES_EXPORTER": "otlp" if traces else "none",
        "OTEL_METRICS_EXPORTER": "otlp" if metrics else "none",
        "OTEL_LOGS_EXPORTER": "otlp" if logs else "none",
    }
    if traces:
        env["OTEL_BSP_SCHEDULE_DELAY"] = "100"
    if metrics:
        env["OTEL_METRIC_EXPORT_INTERVAL"] = "1000"
    if logs:
        env["OTEL_BLRP_SCHEDULE_DELAY"] = "100"
    if per_signal_endpoints:
        if traces:
            env["OTEL_EXPORTER_OTLP_TRACES_ENDPOINT"] = endpoint + "/v1/traces"
        if metrics:
            env["OTEL_EXPORTER_OTLP_METRICS_ENDPOINT"] = endpoint + "/v1/metrics"
        if logs:
            env["OTEL_EXPORTER_OTLP_LOGS_ENDPOINT"] = endpoint + "/v1/logs"
    else:
        env["OTEL_EXPORTER_OTLP_ENDPOINT"] = endpoint
    env.update(extra)
    return env

def otel_injection(rootfs, env = {}, prepend_path = {}, append_path = {}, require = []):
    """Returns generic launcher flags and their instrumentation rootfs."""
    flags = ["--otel-rootfs=$(rlocationpath {})".format(rootfs)]
    flags.extend(["--prepend-path={}={}".format(key, prepend_path[key]) for key in sorted(prepend_path)])
    flags.extend(["--append-path={}={}".format(key, append_path[key]) for key in sorted(append_path)])
    flags.extend(["--env={}={}".format(key, env[key]) for key in sorted(env)])
    flags.extend(["--require={}".format(path) for path in require])
    return struct(rootfs = rootfs, flags = flags)

def instrumentation_injection(rootfs, env = {}, prepend_path = {}, append_path = {}, require = []):
    """Returns neutral injection flags without exporter or service defaults."""
    flags = ["--instrumentation-rootfs=$(rlocationpath {})".format(rootfs)]
    flags.extend(["--prepend-path={}={}".format(key, prepend_path[key]) for key in sorted(prepend_path)])
    flags.extend(["--append-path={}={}".format(key, append_path[key]) for key in sorted(append_path)])
    flags.extend(["--env={}={}".format(key, env[key]) for key in sorted(env)])
    flags.extend(["--require={}".format(path) for path in require])
    return struct(rootfs = rootfs, flags = flags)

def datadog_python_injection(rootfs = Label("//harness:datadog_python_rootfs"), aiohttp = False):
    """Activates the pinned dd-trace-py package through Python sitecustomize."""
    payload = "{instrumentation_rootfs}"
    return instrumentation_injection(
        rootfs = rootfs,
        env = {
            "RULES_STESTS_DATADOG_AIOHTTP_ENABLED": "true",
            # aiosqlite executes DB-API calls on a private worker thread with
            # no request context. Trace its SQLAlchemy engine before work is
            # queued, using ddtrace's supported SQLAlchemy integration.
            "DD_TRACE_SQLALCHEMY_ENABLED": "true",
            "DD_TRACE_SQLITE3_ENABLED": "false",
        } if aiohttp else {},
        prepend_path = {"PYTHONPATH": payload},
        require = [payload + "/sitecustomize.py", payload + "/ddtrace_pkgs"],
    )

def datadog_ruby_injection(rootfs = Label("//harness:datadog_ruby_rootfs")):
    """Activates a locked, ABI-matched Datadog payload before Rails boots."""
    payload = "{instrumentation_rootfs}/datadog-ruby"
    return instrumentation_injection(
        rootfs = rootfs,
        env = {
            "RULES_STESTS_DATADOG_RUBY_ROOT": payload,
            "RUBYOPT": "-r" + payload + "/activation.rb",
        },
        require = [payload + "/activation.rb", payload + "/abi.json", payload + "/specifications"],
    )

def datadog_env(service = "realworld-datadog", wire_version = "v0.5", sink = Label("//harness:telemetry_sink_service"), extra = {}):
    """Returns deterministic traces-only Datadog intake configuration."""
    if wire_version not in ["v0.4", "v0.5"]:
        fail("Datadog intake wire_version must be v0.4 or v0.5")
    if not service:
        fail("Datadog requires a non-empty service identity")
    env = {
        "DD_SERVICE": service,
        "DD_ENV": "test",
        "DD_VERSION": "1",
        "DD_TRACE_ENABLED": "true",
        "DD_TRACE_AGENT_URL": "http://127.0.0.1:$${%s}" % str(native.package_relative_label(sink)),
        "DD_TRACE_API_VERSION": wire_version,
        "DD_TRACE_SAMPLING_RULES": '[{"sample_rate":1.0}]',
        "DD_TRACE_RATE_LIMIT": "-1",
        "DD_TRACE_WRITER_INTERVAL_SECONDS": "0.1",
        "DD_TRACE_PARTIAL_FLUSH_ENABLED": "false",
        "DD_TRACE_SPAN_ATTRIBUTE_SCHEMA": "v0",
        "DD_TRACE_PROPAGATION_STYLE_EXTRACT": "datadog,tracecontext",
        "DD_TRACE_PROPAGATION_STYLE_INJECT": "datadog,tracecontext",
        "DD_TRACE_128_BIT_TRACEID_GENERATION_ENABLED": "true",
        "DD_INSTRUMENTATION_TELEMETRY_ENABLED": "false",
        "DD_REMOTE_CONFIGURATION_ENABLED": "false",
        "DD_RUNTIME_METRICS_ENABLED": "false",
        "DD_PROFILING_ENABLED": "false",
        "DD_APPSEC_ENABLED": "false",
        "DD_IAST_ENABLED": "false",
        "DD_SCA_ENABLED": "false",
        "DD_DYNAMIC_INSTRUMENTATION_ENABLED": "false",
        "DD_EXCEPTION_REPLAY_ENABLED": "false",
        "DD_DATA_STREAMS_ENABLED": "false",
        "DD_LLMOBS_ENABLED": "false",
        "DD_LOGS_INJECTION": "false",
        "DD_TRACE_COMPUTE_STATS": "false",
        "DD_CODE_ORIGIN_FOR_SPANS_ENABLED": "false",
        "DD_TRACE_OTEL_ENABLED": "false",
        "DD_TRACE_STARTUP_LOGS": "false",
    }
    env.update(extra)
    return env

def python_auto_injection(rootfs = Label("//harness:otel_python_rootfs")):
    """Returns the standard Python auto-instrumentation injection."""
    auto = "{otel_rootfs}/autoinstrumentation/opentelemetry/instrumentation/auto_instrumentation"
    return otel_injection(
        rootfs = rootfs,
        prepend_path = {"PYTHONPATH": auto},
        append_path = {"PYTHONPATH": "{otel_rootfs}/autoinstrumentation"},
        require = [auto + "/sitecustomize.py"],
    )

def ruby_auto_injection(rootfs = Label("//harness:otel_ruby_rootfs")):
    """Returns the standard Ruby auto-instrumentation injection."""
    payload = "{otel_rootfs}/otel-auto-instrumentation-ruby"
    return otel_injection(
        rootfs = rootfs,
        env = {
            "OTEL_RUBY_ADDITIONAL_GEM_PATH": payload,
            "RUBYOPT": "-r" + payload + "/activation.rb",
        },
        require = [payload + "/activation.rb", payload + "/gems"],
    )

def otel_variant(profile, env, scenarios):
    """Declares one OTEL_* environment variant of an instrumented suite.

    A variant is its own profile, so it owns the contract clause the variable
    changes, its own recorded shapes, its own receipts, and its own column in
    the parity report.
    """
    if not profile:
        fail("an OpenTelemetry variant requires its own profile label")
    if not env:
        fail("an OpenTelemetry variant must set at least one environment variable")
    if not scenarios:
        fail("an OpenTelemetry variant must run at least one scenario")
    return struct(profile = profile, env = env, scenarios = scenarios)

def _service_config(application, binary = None):
    if application.runtime == "exec":
        return dict(runtime = "native", command = binary, args = application.command)
    return dict(
        runtime = application.runtime,
        command = application.command[0],
        args = application.command[1:],
    )

def realworld_app_suite(
        name,
        app,
        profile = None,
        injection = None,
        rootfs = None,
        otel_binary = None,
        env = None,
        plain = False,
        instance = None,
        otel_candidates = True,
        otel_flaky_reason = "",
        otel_flaky_cases = {},
        otel_xfails = {},
        expected_start_duration = None,
        manual = None,
        tags = [],
        scenarios = REALWORLD_BASE_HURL_CASES,
        variants = {},
        flaky = False,
        **kwargs):
    """Emits services, probes, and sharded Hurl tests for a catalog app."""
    if app not in REALWORLD_APPS:
        fail("unknown RealWorld app {!r}; expected one of {}".format(app, ", ".join(sorted(REALWORLD_APPS))))
    application = REALWORLD_APPS[app]
    overridden_rootfs = rootfs != None
    selected_rootfs = rootfs or application.rootfs
    is_manual = application.manual if manual == None else manual
    suite_tags = tags + (["manual"] if is_manual else [])
    duration = expected_start_duration or application.expected_start_duration

    if application.runtime == "exec" and injection:
        fail("injection is not supported for exec apps; provide rootfs and otel_binary")
    if profile and application.runtime != "exec" and not injection and not overridden_rootfs:
        fail("injection is required for catalog Python and Ruby rootfs images")
    if profile and application.runtime == "exec" and not (otel_binary or application.otel_binary):
        fail("otel_binary is required for exec apps")

    common = {
        "autoassign_port": True,
        "expected_start_duration": duration,
        "http_health_check_address": "http://127.0.0.1:$${PORT}/api/tags",
        "shutdown_timeout": "10s",
        "so_reuseport_aware": application.so_reuseport_aware,
        "tags": suite_tags,
    }

    if plain:
        plain_service = name + "_service"
        corpus_service(
            name = plain_service,
            rootfs = selected_rootfs,
            instance = app,
            hygienic = False,
            **dict(common, **_service_config(
                application,
                binary = application.binary if application.runtime == "exec" else None,
            ))
        )
        realworld_service_tests(
            name = name,
            service = ":" + plain_service,
            scenarios = scenarios,
            flaky = flaky,
            tags = suite_tags,
            **kwargs
        )

    if not profile:
        return
    _otel_targets(
        name = name,
        application = application,
        rootfs = selected_rootfs,
        injection = injection,
        otel_binary = otel_binary,
        instance = instance or app + "-otel",
        profile = profile,
        env = env,
        scenarios = scenarios,
        common = common,
        suite_tags = suite_tags,
        flaky = flaky,
        otel_candidates = otel_candidates,
        otel_flaky_reason = otel_flaky_reason,
        otel_flaky_cases = otel_flaky_cases,
        otel_xfails = otel_xfails,
        **kwargs
    )
    for variant_name in sorted(variants):
        variant = variants[variant_name]
        # A variant inherits the suite's exporter environment and then states
        # only the variables it is there to exercise, so the two runs differ by
        # exactly the declaration in this table.
        variant_env = dict(otlp_env() if env == None else env)
        variant_env.update(variant.env)
        _otel_targets(
            name = name + "_" + variant_name,
            application = application,
            rootfs = selected_rootfs,
            injection = injection,
            otel_binary = otel_binary,
            instance = instance or app + "-otel",
            profile = variant.profile,
            env = variant_env,
            scenarios = variant.scenarios,
            common = common,
            suite_tags = suite_tags,
            flaky = flaky,
            otel_candidates = otel_candidates,
            otel_flaky_reason = otel_flaky_reason,
            otel_flaky_cases = {},
            otel_xfails = {},
            **kwargs
        )

def _otel_targets(
        name,
        application,
        rootfs,
        injection,
        otel_binary,
        instance,
        profile,
        env,
        scenarios,
        common,
        suite_tags,
        flaky,
        otel_candidates,
        otel_flaky_reason,
        otel_flaky_cases,
        otel_xfails,
        **kwargs):
    """Emits the instrumented service, its probes, and its sharded Hurl tests."""
    otel_service = name + "_otel_service"
    service_env = dict(otlp_env() if env == None else env)
    if application.runtime != "exec" and not injection and "OTEL_SERVICE_NAME" not in service_env:
        service_env["OTEL_SERVICE_NAME"] = instance
    corpus_service(
        name = otel_service,
        rootfs = rootfs,
        instance = instance,
        injection = injection,
        deps = [_SINK],
        env = service_env,
        hygienic = False,
        **dict(common, **_service_config(
            application,
            binary = otel_binary or (application.otel_binary if application.runtime == "exec" else None),
        ))
    )
    realworld_service_tests(
        name = name + "_otel",
        service = ":" + otel_service,
        profile = profile,
        scenarios = scenarios,
        otel_candidates = otel_candidates,
        otel_flaky_reason = otel_flaky_reason,
        otel_flaky_cases = otel_flaky_cases,
        otel_xfails = otel_xfails,
        flaky = flaky,
        tags = suite_tags,
        **kwargs
    )
