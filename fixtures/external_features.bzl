"""Differential external SDK experiments using the same fixture workload."""

load("@rules_itest//:itest.bzl", "service_test")
load("//rules:realworld_app.bzl", "REALWORLD_APPS", "python_auto_injection", "ruby_auto_injection")

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
