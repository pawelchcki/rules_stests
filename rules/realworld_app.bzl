"""Public RealWorld application and OpenTelemetry test-suite macros."""

load("@rules_itest//:itest.bzl", "itest_service", "service_test")
load("//bazel:oci_images.lock.bzl", "RUBY_IMAGES_PUBLISHED")
load("//rules:hurl_test.bzl", "REALWORLD_BASE_HURL_CASES", "realworld_hurl_test_suite")

_SINK = Label("//harness:otel_sink_service")
_LAUNCHER = Label("//harness:oci_bundle")
_PROBE = Label("//harness:api_probe")
_EXIT0 = Label("@rules_itest//:exit0")

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

def _rlocation(label):
    return "$(rlocationpath {})".format(label)

def _service_suffix(name):
    package = native.package_name()
    return "//{}:{}".format(package, name) if package else "//:" + name

def _launcher_args(application, rootfs, instance, injection = None, binary = None):
    modes = {"python": "app", "ruby": "app-ruby", "exec": "app-exec"}
    args = [modes[application.runtime]]
    if injection:
        args.extend(injection.flags)
    args.extend([instance, _rlocation(rootfs)])
    if application.runtime == "exec":
        args.append(binary)
    args.extend(application.command)
    return args

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
        "exe": _LAUNCHER,
        "expected_start_duration": duration,
        "http_health_check_address": "http://127.0.0.1:$${PORT}/api/tags",
        "shutdown_timeout": "10s",
        "so_reuseport_aware": application.so_reuseport_aware,
        "tags": suite_tags,
    }

    if plain:
        plain_service = name + "_service"
        itest_service(
            name = plain_service,
            args = _launcher_args(
                application,
                selected_rootfs,
                app,
                binary = application.binary if application.runtime == "exec" else None,
            ),
            data = [selected_rootfs],
            hygienic = False,
            **common
        )
        service_test(
            name = plain_service + "_hygiene_test",
            flaky = flaky,
            services = [":" + plain_service],
            tags = suite_tags,
            test = _EXIT0,
        )
        service_test(
            name = name + "_test",
            timeout = "moderate",
            args = ["--service-suffix=" + _service_suffix(plain_service)],
            flaky = flaky,
            services = [":" + plain_service],
            tags = suite_tags,
            test = _PROBE,
        )
        realworld_hurl_test_suite(
            name = name + "_hurl_test",
            cases = scenarios,
            flaky = flaky,
            timeout = "moderate",
            service = ":" + plain_service,
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
    data = [rootfs]
    if injection:
        data.append(injection.rootfs)
    itest_service(
        name = otel_service,
        args = _launcher_args(
            application,
            rootfs,
            instance,
            injection = injection,
            binary = otel_binary or (application.otel_binary if application.runtime == "exec" else None),
        ),
        data = data,
        deps = [_SINK],
        env = service_env,
        hygienic = False,
        **common
    )
    service_test(
        name = otel_service + "_hygiene_test",
        flaky = flaky,
        services = [":" + otel_service],
        tags = suite_tags,
        test = _EXIT0,
    )
    service_test(
        name = name + "_otel_test",
        timeout = "moderate",
        args = ["--service-suffix=" + _service_suffix(otel_service)],
        flaky = flaky,
        services = [":" + otel_service],
        tags = suite_tags,
        test = _PROBE,
    )
    realworld_hurl_test_suite(
        name = name + "_otel_hurl_test",
        cases = scenarios,
        flaky = flaky,
        timeout = "moderate",
        otel_candidates = otel_candidates,
        otel_flaky_reason = otel_flaky_reason,
        otel_flaky_cases = otel_flaky_cases,
        otel_profile = profile,
        otel_sink = _SINK,
        otel_xfails = otel_xfails,
        service = ":" + otel_service,
        tags = suite_tags,
        **kwargs
    )
