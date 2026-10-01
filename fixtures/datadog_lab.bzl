"""Standalone pinned Python Datadog SDK tracing lab."""

load("@rules_itest//:itest.bzl", "service_test")
load("//rules:realworld_app.bzl", "datadog_python_injection")

def datadog_lab_tests():
    app = "//fixtures/apps/python/datadog-lab:app.py"
    rootfs = "//harness:aiohttp_rootfs"
    injection = datadog_python_injection()
    tests = []
    for wire in ["v0.4", "v0.5"]:
        name = "datadog_lab_" + wire.replace(".", "") + "_test"
        service_test(
            name = name,
            timeout = "long",
            services = ["//harness:otel_sink_service"],
            test = "//harness/datadog_lab:probe",
            data = [app, rootfs, injection.rootfs, "//harness:app_launcher"],
            args = [
                "--wire=" + wire,
                "--launcher=$(rlocationpath //harness:app_launcher)",
                "--rootfs=$(rlocationpath {})".format(rootfs),
                "--app=$(rlocationpath {})".format(app),
            ] + ["--injection-flag=" + flag for flag in injection.flags],
            tags = ["datadog", "lab"],
        )
        tests.append(":" + name)
    native.test_suite(name = "datadog_lab_suite", tests = tests)
