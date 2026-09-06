"""RealWorld checks attached to explicitly declared services."""

load("@rules_itest//:itest.bzl", "service_test")
load("//rules:hurl_test.bzl", "REALWORLD_BASE_HURL_CASES", "realworld_hurl_test_suite")

_SINK = Label("//harness:otel_sink_service")
_PROBE = Label("//harness:api_probe")
_EXIT0 = Label("@rules_itest//:exit0")

def realworld_service_tests(
        name,
        service,
        profile = None,
        otel_sink = _SINK,
        scenarios = REALWORLD_BASE_HURL_CASES,
        otel_candidates = True,
        otel_flaky_reason = "",
        otel_flaky_cases = {},
        otel_xfails = {},
        flaky = False,
        tags = [],
        **kwargs):
    """Creates hygiene, API smoke and Hurl tests without creating a service.

    Args:
        name: Test prefix; emits <name>_test, <name>_service_hygiene_test,
            and <name>_hurl_test (plus scenario and candidate targets).
        service: Existing service label, normally from corpus_service.
            Set hygienic = False there to let this suite own the hygiene test.
        profile: Optional atomic OpenTelemetry profile; enables OTel checks.
        otel_sink: Sink label used when profile is supplied. The service must
            declare its own sink dependency and exporter environment.
        scenarios: RealWorld scenario names to test.
        otel_candidates: Generate manual shape-candidate targets.
        otel_flaky_reason: Retry reason for every instrumented scenario.
        otel_flaky_cases: Per-scenario retry reasons.
        otel_xfails: Expected Scheme contract rejections by scenario.
        flaky: Retry hygiene, API smoke and eligible scenario tests.
        tags: Tags applied to the tests.
        **kwargs: Additional options for realworld_hurl_test_suite.
    """
    label = native.package_relative_label(service)
    service_test(
        name = name + "_service_hygiene_test",
        services = [service],
        flaky = flaky,
        tags = tags,
        test = _EXIT0,
    )
    service_test(
        name = name + "_test",
        timeout = "moderate",
        args = ["--service-suffix=//{}:{}".format(label.package, label.name)],
        services = [service],
        flaky = flaky,
        tags = tags,
        test = _PROBE,
    )
    realworld_hurl_test_suite(
        name = name + "_hurl_test",
        timeout = "moderate",
        service = service,
        cases = scenarios,
        otel_profile = profile,
        otel_sink = otel_sink if profile else None,
        otel_candidates = otel_candidates,
        otel_flaky_reason = otel_flaky_reason,
        otel_flaky_cases = otel_flaky_cases,
        otel_xfails = otel_xfails,
        flaky = flaky,
        # Report assembly reads these instrumented scenario receipts.
        tags = tags + (["otel-report"] if profile else []),
        **kwargs
    )
