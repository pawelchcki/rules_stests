"""Configuration variants for the standalone Python SDK workload."""

load("@rules_itest//:itest.bzl", "service_test")
load("//rules:corpus_service.bzl", "corpus_service")
load("//rules:realworld_app.bzl", "otlp_env", "python_auto_injection")

_PYTHON_APP = "//fixtures/apps/python/telemetry-lab:app.py"

def python_telemetry_lab_variants():
    for variant, config in {
        "links_count": struct(scenario = "links-count", env = {"OTEL_SPAN_LINK_COUNT_LIMIT": "2"}),
        "link_attributes": struct(scenario = "link-attributes", env = {"OTEL_LINK_ATTRIBUTE_COUNT_LIMIT": "1"}),
        "span_events": struct(scenario = "span-events", env = {"OTEL_SPAN_EVENT_COUNT_LIMIT": "1"}),
        "event_attributes": struct(scenario = "event-attributes", env = {"OTEL_EVENT_ATTRIBUTE_COUNT_LIMIT": "1"}),
        "attribute_count": struct(scenario = "attribute-count", env = {"OTEL_ATTRIBUTE_COUNT_LIMIT": "4"}),
        "span_value_length": struct(scenario = "span-value-length", env = {"OTEL_SPAN_ATTRIBUTE_VALUE_LENGTH_LIMIT": "3"}),
        "attribute_value_length": struct(scenario = "attribute-value-length", env = {"OTEL_ATTRIBUTE_VALUE_LENGTH_LIMIT": "3"}),
        "resource_attributes": struct(scenario = "resource-attributes", env = {"OTEL_RESOURCE_ATTRIBUTES": "lab.resource=present"}),
        "default_service": struct(scenario = "default-service", env = {"OTEL_SERVICE_NAME": ""}),
        "disabled": struct(scenario = "disabled", env = {"OTEL_SDK_DISABLED": "true"}),
        "sampler_off": struct(scenario = "sampler-off", env = {"OTEL_TRACES_SAMPLER": "always_off"}),
        "sampler_arg_zero": struct(scenario = "sampler-arg-zero", env = {"OTEL_TRACES_SAMPLER": "traceidratio", "OTEL_TRACES_SAMPLER_ARG": "0"}),
        "sampler_arg_one": struct(scenario = "sampler-arg-one", env = {"OTEL_TRACES_SAMPLER": "traceidratio", "OTEL_TRACES_SAMPLER_ARG": "1"}),
        "log_count": struct(scenario = "log-count", env = {"OTEL_LOGRECORD_ATTRIBUTE_COUNT_LIMIT": "1"}),
        "log_length": struct(scenario = "log-length", env = {"OTEL_LOGRECORD_ATTRIBUTE_VALUE_LENGTH_LIMIT": "8"}),
        "log_length_edge": struct(scenario = "log-length-edge", env = {"OTEL_LOGRECORD_ATTRIBUTE_VALUE_LENGTH_LIMIT": "8"}),
        "ot_baggage_hyphen": struct(scenario = "ot-baggage-hyphen", env = {}),
        "exemplars_off": struct(scenario = "exemplars-off", env = {"OTEL_METRICS_EXEMPLAR_FILTER": "always_off"}),
        "histogram_exponential": struct(scenario = "histogram-exponential", env = {"OTEL_EXPORTER_OTLP_METRICS_DEFAULT_HISTOGRAM_AGGREGATION": "base2_exponential_bucket_histogram"}),
    }.items():
        environment = {
            "OTEL_SERVICE_NAME": "python-telemetry-lab",
            "OTEL_PYTHON_LOGGING_AUTO_INSTRUMENTATION_ENABLED": "true",
        }
        environment.update(config.env)
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
            env = otlp_env(extra = environment),
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
