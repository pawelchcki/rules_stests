"""Sharded RealWorld Hurl tests using an atomic OpenTelemetry profile."""

load("@rules_itest//:itest.bzl", "service_test")
load(
    "//corpus:registry.bzl",
    _BASE_CASES = "REALWORLD_BASE_HURL_CASES",
    _CASES = "REALWORLD_HURL_CASES",
    _LOCAL_CASES = "REALWORLD_LOCAL_HURL_CASES",
)

_HURL_ROOTFS = Label("//harness:hurl_rootfs")
_DRIVER = Label("//harness:realworld_hurl")
_SPEC_ANCHOR = Label("@realworld_api_specs//:hurl_all")

REALWORLD_HURL_CASES = _CASES
REALWORLD_BASE_HURL_CASES = _BASE_CASES

def _rootpath(label):
    return "$(rlocationpath {})".format(str(label))

def _realworld_hurl_case_test(name, case, service, otel_sink = None,
                              otel_profile = None, otel_mode = "validate",
                              otel_xfail = "", flaky = False, tags = [], **kwargs):
    spec = _LOCAL_CASES.get(case) or _SPEC_ANCHOR.same_package_label("hurl/{}.hurl".format(case))
    args = [
        "--service-suffix=" + str(service),
        "--jobs=1",
        "--hurl-rootfs=" + _rootpath(_HURL_ROOTFS),
    ]
    data = [_HURL_ROOTFS, spec]
    if otel_sink:
        args.extend([
            "--otel-sink-suffix=" + str(otel_sink),
            "--otel-mode=" + otel_mode,
            "--otel-case=" + case,
            "--otel-profile-manifest=" + _rootpath(otel_profile),
        ])
        data.append(otel_profile)
        if otel_xfail:
            args.append("--otel-xfail=" + otel_xfail)
    args.append(_rootpath(spec))
    service_test(
        name = name,
        args = args,
        data = data,
        services = [service],
        flaky = flaky,
        tags = tags,
        test = _DRIVER,
        **kwargs
    )

def realworld_hurl_test_suite(name, service, otel_sink = None,
                              otel_profile = None, otel_candidates = True,
                              otel_flaky_reason = "", otel_flaky_cases = {},
                              otel_xfails = {}, flaky = False, tags = [],
                              cases = REALWORLD_BASE_HURL_CASES, **kwargs):
    """Creates one test per RealWorld scenario from one atomic profile label."""
    if bool(otel_sink) != bool(otel_profile):
        fail("otel_sink and the atomic otel_profile label must be supplied together")
    if not cases:
        fail("cases must contain at least one RealWorld scenario")
    unknown_cases = [case for case in cases if case not in REALWORLD_HURL_CASES]
    if unknown_cases:
        fail("cases contains unknown scenarios: {}".format(", ".join(sorted(unknown_cases))))
    if len({case: True for case in cases}) != len(cases):
        fail("cases contains duplicate scenarios")
    unknown_xfails = [case for case in otel_xfails if case not in cases]
    unknown_flaky = [case for case in otel_flaky_cases if case not in cases]
    if unknown_xfails:
        fail("otel_xfails contains unknown cases: {}".format(", ".join(sorted(unknown_xfails))))
    if unknown_flaky:
        fail("otel_flaky_cases contains unknown cases: {}".format(", ".join(sorted(unknown_flaky))))
    if (otel_xfails or otel_flaky_cases) and not otel_sink:
        fail("OpenTelemetry xfail/flaky declarations require otel_sink")
    overlap = [case for case in otel_xfails if case in otel_flaky_cases]
    if overlap:
        fail("cases cannot be both flaky and xfail: {}".format(", ".join(sorted(overlap))))

    tests, candidates = [], []
    for case in cases:
        test_name = name + "_" + case
        xfail_reason = otel_xfails.get(case, "")
        if case in otel_xfails and not xfail_reason:
            fail("otel_xfails reason for {} must be non-empty".format(case))
        flaky_reason = otel_flaky_cases.get(case, otel_flaky_reason)
        if case in otel_flaky_cases and not flaky_reason:
            fail("otel_flaky_cases reason for {} must be non-empty".format(case))
        case_is_flaky = not xfail_reason and (flaky or bool(flaky_reason))
        case_tags = tags + (["otel-xfail"] if xfail_reason else []) + (["otel-flaky"] if case_is_flaky else [])
        _realworld_hurl_case_test(
            name = test_name,
            case = case,
            service = service,
            otel_sink = otel_sink,
            otel_profile = otel_profile,
            otel_xfail = xfail_reason,
            flaky = case_is_flaky,
            tags = case_tags,
            **kwargs
        )
        tests.append(":" + test_name)
        if otel_sink and otel_candidates:
            candidate_name = test_name + "_shape_candidate"
            _realworld_hurl_case_test(
                name = candidate_name,
                case = case,
                service = service,
                otel_sink = otel_sink,
                otel_profile = otel_profile,
                otel_mode = "candidate",
                flaky = case_is_flaky,
                tags = tags + ["manual"],
                **kwargs
            )
            candidates.append(":" + candidate_name)
    native.test_suite(name = name, tests = tests, tags = tags)
    if candidates:
        native.test_suite(
            name = name + "_shape_candidates",
            tests = candidates,
            tags = tags + ["manual"],
        )
