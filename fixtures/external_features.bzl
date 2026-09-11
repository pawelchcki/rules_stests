"""Differential external SDK experiments using the same fixture workload."""

load("@rules_itest//:itest.bzl", "service_test")
load("//rules:corpus_service.bzl", "corpus_service")
load("//rules:hurl_test.bzl", "realworld_parallel_hurl_test")
load("//corpus:registry.bzl", "REALWORLD_BASE_HURL_CASES")
load("//rules:realworld_app.bzl", "datadog_env", "REALWORLD_APPS", "datadog_python_injection", "datadog_ruby_injection", "python_auto_injection", "ruby_auto_injection")

def external_feature_tests():
    tests = []
    for app, config in REALWORLD_APPS.items():
        rootfs = config.rootfs
        args = [
            "--runtime=" + ("native" if config.runtime == "exec" else config.runtime),
            "--rootfs=$(rlocationpath {})".format(rootfs),
        ]
        data = [rootfs, "//harness:app_launcher", "//harness/external_features:expected.json"]
        if config.runtime in ["python", "ruby"]:
            injection = python_auto_injection() if config.runtime == "python" else ruby_auto_injection()
            args += injection.flags
            data.append(injection.rootfs)
        command = config.command
        if config.runtime == "exec":
            command = [config.otel_binary] + command
        args += ["--"] + [arg.replace("$${PORT}", "{PORT}") for arg in command]
        name = app + "_external_features_test"
        service_test(
            name = name,
            timeout = "long",
            services = ["//harness:otel_sink_service"],
            test = "//harness/external_features:probe",
            data = data,
            args = [
                "--app=" + app,
                "--launcher=$(rlocationpath //harness:app_launcher)",
                "--expected=$(rlocationpath //harness/external_features:expected.json)",
                "--launch-args='" + json.encode(args) + "'",
            ],
            tags = ["external-features"] + (["manual"] if config.manual else []),
        )
        if not config.manual:
            tests.append(":" + name)
    native.test_suite(name = "external_features_test", tests = tests)

def _datadog_fixture(app):
    config = REALWORLD_APPS[app]
    return struct(
        rootfs = "//harness:gin_datadog_rootfs" if app == "gin" else config.rootfs,
        runtime = "native" if app == "gin" else config.runtime,
        command = ["opt/app/bin/realworld-gin-datadog"] + config.command if app == "gin" else config.command,
        injection = datadog_ruby_injection() if app == "rails" else (None if app == "gin" else datadog_python_injection(aiohttp = app == "aiohttp")),
        wires = ["v0.4"] if app in ["rails", "gin"] else ["v0.4", "v0.5"],
        profile = {"rails": "ruby-rails-datadog-v2-42-0-", "gin": "go-gin-datadog-v2-10-1-"}.get(app, "python-" + app + "-datadog-v4-14-0-"),
    )

def datadog_external_feature_tests():
    tests = []
    for app in ["aiohttp", "django", "rails", "gin"]:
        config = _datadog_fixture(app)
        args = ["--runtime=" + config.runtime, "--rootfs=$(rlocationpath {})".format(config.rootfs)]
        data = [config.rootfs, "//harness:app_launcher"]
        if config.injection:
            args += config.injection.flags
            data.append(config.injection.rootfs)
        args += ["--"] + [arg.replace("$${PORT}", "{PORT}") for arg in config.command]
        for wire in config.wires:
            name = app + "_datadog_external_features_" + wire.replace(".", "")
            service_test(
                name = name,
                timeout = "long",
                services = ["//harness:otel_sink_service"],
                test = "//harness/external_features:probe",
                data = data,
                args = ["--protocol=datadog", "--wire-version=" + wire, "--app=" + app,
                        "--launcher=$(rlocationpath //harness:app_launcher)",
                        "--launch-args='" + json.encode(args) + "'"],
                tags = ["datadog", "external-features"] + (["manual"] if app in ["rails", "gin"] else []),
            )
            tests.append(":" + name)
    native.test_suite(name = "datadog_external_features_suite", tests = tests)

def datadog_parallel_tests():
    tests = []
    sink = "//harness:datadog_stress_sink_service"
    for app in ["aiohttp", "django", "rails", "gin"]:
        config = _datadog_fixture(app)
        for wire in config.wires:
            suffix = wire.replace(".", "")
            name = app + "_datadog_" + suffix + "_parallel"
            corpus_service(
                name = name + "_service",
                rootfs = config.rootfs,
                runtime = config.runtime,
                instance = app + "-datadog-stress",
                command = config.command[0],
                args = config.command[1:],
                injection = config.injection,
                env = datadog_env(service = app + "-datadog", wire_version = wire, sink = sink, extra = {
                    "RULES_STESTS_SQL_MARKERS": "true",
                    "DD_TRACE_HEADER_TAGS": "x-rules-stests-request-id:rules_stests.request_id",
                }),
                deps = [sink],
                so_reuseport_aware = app != "rails",
                autoassign_port = True,
                expected_start_duration = "5s",
                http_health_check_address = "http://127.0.0.1:$${PORT}/api/tags",
                hygienic = False,
                shutdown_timeout = "10s",
                tags = ["manual"],
            )
            realworld_parallel_hurl_test(
                name = name + "_test",
                service = ":" + name + "_service",
                profile = "//corpus:" + config.profile + suffix,
                sink = sink,
                cases = REALWORLD_BASE_HURL_CASES + ["propagation_datadog"],
            )
            tests.append(":" + name + "_test")
    native.test_suite(name = "datadog_parallel_suite", tests = tests, tags = ["manual"])
