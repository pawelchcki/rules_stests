"""Configuration variants for the standalone Python SDK workload."""

load("@rules_itest//:itest.bzl", "service_test")
load("//rules:corpus_service.bzl", "corpus_service")
load("//rules:realworld_app.bzl", "otlp_env", "python_auto_injection")

_PYTHON_APP = "//fixtures/apps/python/telemetry-lab:app.py"

def python_telemetry_lab_variants():
    for variant, config in {
        "links_count": struct(scenario = "links-count", variable = "OTEL_SPAN_LINK_COUNT_LIMIT", value = "2"),
        "link_attributes": struct(scenario = "link-attributes", variable = "OTEL_LINK_ATTRIBUTE_COUNT_LIMIT", value = "1"),
        "span_events": struct(scenario = "span-events", variable = "OTEL_SPAN_EVENT_COUNT_LIMIT", value = "1"),
        "event_attributes": struct(scenario = "event-attributes", variable = "OTEL_EVENT_ATTRIBUTE_COUNT_LIMIT", value = "1"),
        "attribute_count": struct(scenario = "attribute-count", variable = "OTEL_ATTRIBUTE_COUNT_LIMIT", value = "4"),
        "span_value_length": struct(scenario = "span-value-length", variable = "OTEL_SPAN_ATTRIBUTE_VALUE_LENGTH_LIMIT", value = "3"),
        "attribute_value_length": struct(scenario = "attribute-value-length", variable = "OTEL_ATTRIBUTE_VALUE_LENGTH_LIMIT", value = "3"),
        "resource_attributes": struct(scenario = "resource-attributes", variable = "OTEL_RESOURCE_ATTRIBUTES", value = "lab.resource=present"),
    }.items():
        service_name = "python_telemetry_lab_" + variant + "_service"
        corpus_service(
            name = service_name,
            rootfs = "//harness:aiohttp_rootfs",
            runtime = "python",
            instance = "python-lab-" + variant.replace("_", "-"),
            command = "$(rlocationpath {})".format(_PYTHON_APP),
            args = ["--port", "$${PORT}"],
            data = [_PYTHON_APP],
            injection = python_auto_injection(),
            env = otlp_env(extra = {
                "OTEL_SERVICE_NAME": "python-telemetry-lab",
                "OTEL_PYTHON_LOGGING_AUTO_INSTRUMENTATION_ENABLED": "true",
                config.variable: config.value,
            }),
            deps = ["//harness:otel_sink_service"],
            autoassign_port = True,
            http_health_check_address = "http://127.0.0.1:$${PORT}/healthz",
            so_reuseport_aware = True,
            hygienic = False,
        )
        service_test(
            name = "python_telemetry_lab_" + variant + "_test",
            services = [":" + service_name],
            test = "//harness:telemetry_lab_probe",
            data = [_PYTHON_APP, "//fixtures:python_telemetry_lab_plan"],
            args = [
                "--app-suffix=//fixtures:" + service_name,
                "--sink-suffix=//harness:otel_sink_service",
                "--language=python",
                "--scenario=" + config.scenario,
                "--source=$(rlocationpath {})".format(_PYTHON_APP),
                "--proof-plan=$(rlocationpath //fixtures:python_telemetry_lab_plan)",
            ],
            tags = ["telemetry"],
        )
