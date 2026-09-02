"""Compact declarations for the repository's reference applications."""

load("@rules_itest//:itest.bzl", "itest_service", "service_test")
load("//rules:hurl_test.bzl", "realworld_hurl_test_suite")
load("//rules:oci_rootfs.bzl", "oci_rootfs")

_SINK = "//harness:otel_sink_service"
_SINK_ENDPOINT = "http://127.0.0.1:$${@@//harness:otel_sink_service}"

def otlp_env(traces = True, metrics = True, logs = True, per_signal_endpoints = False, extra = {}):
    """Returns consistent OTLP exporter environment variables."""
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
            env["OTEL_EXPORTER_OTLP_TRACES_ENDPOINT"] = _SINK_ENDPOINT + "/v1/traces"
        if metrics:
            env["OTEL_EXPORTER_OTLP_METRICS_ENDPOINT"] = _SINK_ENDPOINT + "/v1/metrics"
        if logs:
            env["OTEL_EXPORTER_OTLP_LOGS_ENDPOINT"] = _SINK_ENDPOINT + "/v1/logs"
    else:
        env["OTEL_EXPORTER_OTLP_ENDPOINT"] = _SINK_ENDPOINT
    env.update(extra)
    return env

def _expand_args(values, rootfs, otel_rootfs):
    result = []
    for value in values:
        if value == "{rootfs}":
            result.append("$(rootpath {})".format(rootfs))
        elif value == "{otel_rootfs}":
            if not otel_rootfs:
                fail("{otel_rootfs} used without otel_rootfs")
            result.append("$(rootpath {})".format(otel_rootfs))
        else:
            result.append(value)
    return result

def realworld_app_fixture(
        name,
        image,
        launch,
        otel_launch,
        otel_env,
        otel_profile,
        otel_rootfs = None,
        so_reuseport_aware = False,
        expected_start_duration = "3s",
        manual = False,
        otel_flaky_reason = "",
        otel_flaky_cases = {},
        otel_xfails = {}):
    """Emits the rootfs, services, smoke probes, and sharded Hurl suites."""
    rootfs = ":{}_rootfs".format(name)
    tags = ["manual"] if manual else []
    oci_rootfs(
        name = name + "_rootfs",
        image = image,
        single_payload = True,
        tags = tags,
    )

    common = {
        "autoassign_port": True,
        "exe": "//harness:oci_bundle",
        "expected_start_duration": expected_start_duration,
        "http_health_check_address": "http://127.0.0.1:$${PORT}/api/tags",
        "shutdown_timeout": "10s",
        "so_reuseport_aware": so_reuseport_aware,
        "tags": tags,
    }
    itest_service(
        name = name + "_service",
        args = _expand_args(launch, rootfs, None),
        data = [rootfs],
        **common
    )
    service_test(
        name = name + "_test",
        timeout = "moderate",
        args = ["--service-suffix=//fixtures:{}_service".format(name)],
        services = [":" + name + "_service"],
        tags = tags,
        test = "//harness:api_probe",
    )
    realworld_hurl_test_suite(
        name = name + "_hurl_test",
        timeout = "moderate",
        service = ":" + name + "_service",
        tags = tags,
    )

    otel_data = [rootfs] + ([otel_rootfs] if otel_rootfs else [])
    itest_service(
        name = name + "_otel_service",
        args = _expand_args(otel_launch, rootfs, otel_rootfs),
        data = otel_data,
        deps = [_SINK],
        env = otel_env,
        **common
    )
    service_test(
        name = name + "_otel_test",
        timeout = "moderate",
        args = ["--service-suffix=//fixtures:{}_otel_service".format(name)],
        services = [":" + name + "_otel_service"],
        tags = tags,
        test = "//harness:api_probe",
    )
    realworld_hurl_test_suite(
        name = name + "_otel_hurl_test",
        timeout = "moderate",
        otel_flaky_reason = otel_flaky_reason,
        otel_flaky_cases = otel_flaky_cases,
        otel_profile = otel_profile,
        otel_sink = _SINK,
        otel_xfails = otel_xfails,
        service = ":" + name + "_otel_service",
        tags = tags,
    )
