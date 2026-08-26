"""Sharded RealWorld Hurl contract tests for rules_itest services."""

load("@rules_itest//:itest.bzl", "service_test")

REALWORLD_HURL_CASES = [
    "articles",
    "auth",
    "comments",
    "errors_articles",
    "errors_auth",
    "errors_authorization",
    "errors_comments",
    "errors_profiles",
    "favorites",
    "feed",
    "pagination",
    "profiles",
    "tags",
]

def _realworld_hurl_case_test(
        name,
        case,
        service,
        otel_sink = None,
        otel_app = None,
        otel_libraries = [],
        otel_imports = [],
        otel_program = None,
        otel_mode = "validate",
        otel_xfail = "",
        flaky = False,
        tags = [],
        **kwargs):
    spec = "@realworld_api_specs//:hurl/{}.hurl".format(case)
    args = [
        "--service-suffix=" + service,
        "--jobs=1",
        "--hurl-rootfs=$(rootpath //bazel/itest:hurl_rootfs)",
    ]
    data = [
        "//bazel/itest:hurl_rootfs",
        spec,
    ]
    if otel_sink:
        args.extend([
            "--otel-sink-suffix=" + otel_sink,
            "--otel-mode=" + otel_mode,
            "--otel-case={}/{}".format(otel_app, case),
        ])
        for library in otel_libraries:
            args.append("--otel-library=$(rootpath {})".format(library))
        for library in otel_imports:
            args.append("--otel-import=" + library)
        if otel_program:
            args.append("--otel-program=$(rootpath {})".format(otel_program))
            data.append(otel_program)
        if otel_xfail:
            args.append("--otel-xfail=" + otel_xfail)
        data.extend(otel_libraries)
    args.append("$(rootpath {})".format(spec))
    service_test(
        name = name,
        args = args,
        data = data,
        services = [service],
        flaky = flaky,
        tags = tags,
        test = "//bazel/itest:realworld_hurl",
        **kwargs
    )

def realworld_hurl_test_suite(
        name,
        service,
        otel_sink = None,
        otel_app = None,
        otel_profile = None,
        otel_profile_library = None,
        otel_runtime_libraries = None,
        otel_detail_pattern = None,
        otel_exact = True,
        otel_candidates = True,
        otel_flaky_cases = {},
        otel_xfails = {},
        flaky = False,
        tags = [],
        **kwargs):
    """Creates one schedulable integration test per upstream Hurl file.

    OTLP validation composes a portable scenario with a named implementation
    profile. Exact mode additionally imports a per-scenario detail library;
    contract mode permits implementation-specific non-server spans.
    """
    if bool(otel_sink) != bool(otel_app):
        fail("otel_sink and otel_app must be supplied together")
    unknown_xfails = [case for case in otel_xfails if case not in REALWORLD_HURL_CASES]
    if unknown_xfails:
        fail("otel_xfails contains unknown cases: {}".format(", ".join(sorted(unknown_xfails))))
    unknown_flaky = [case for case in otel_flaky_cases if case not in REALWORLD_HURL_CASES]
    if unknown_flaky:
        fail("otel_flaky_cases contains unknown cases: {}".format(", ".join(sorted(unknown_flaky))))
    if otel_xfails and not otel_sink:
        fail("otel_xfails requires otel_sink")
    if otel_flaky_cases and not otel_sink:
        fail("otel_flaky_cases requires otel_sink")
    overlapping_cases = [case for case in otel_xfails if case in otel_flaky_cases]
    if overlapping_cases:
        fail("cases cannot be both flaky and xfail: {}".format(", ".join(sorted(overlapping_cases))))
    if otel_sink:
        profile = otel_profile or "python-{}-auto-v0-65b0".format(otel_app)
        profile_library = otel_profile_library or "//bazel/itest/goldens:{}/common.scm".format(otel_app)
        runtime_libraries = otel_runtime_libraries if otel_runtime_libraries != None else ["//bazel/itest/goldens:python.scm"]
        detail_pattern = otel_detail_pattern
    else:
        profile = ""
        profile_library = None
        runtime_libraries = []
        detail_pattern = None
    tests = []
    candidates = []
    for case in REALWORLD_HURL_CASES:
        test_name = name + "_" + case
        xfail_reason = otel_xfails.get(case, "")
        if case in otel_xfails and not xfail_reason:
            fail("otel_xfails reason for {} must be non-empty".format(case))
        flaky_reason = otel_flaky_cases.get(case, "")
        if case in otel_flaky_cases and not flaky_reason:
            fail("otel_flaky_cases reason for {} must be non-empty".format(case))
        case_tags = tags + (["otel-xfail"] if xfail_reason else []) + (["otel-flaky"] if flaky_reason else [])
        libraries = []
        imports = []
        program = None
        if otel_sink:
            libraries = [
                "//bazel/itest/goldens:common.scm",
                "//bazel/itest/goldens:realworld.scm",
            ] + runtime_libraries + [
                profile_library,
                "//bazel/itest/goldens:contracts/{}.scm".format(case),
            ]
            imports = [
                "otel.validation",
                "realworld.contract",
                "realworld.profile.{}".format(profile),
                "realworld.scenario.{}".format(case),
            ]
            if otel_exact:
                detail_library = detail_pattern.format(case) if detail_pattern else "//bazel/itest/goldens:{}/{}.scm".format(otel_app, case)
                libraries.append(detail_library)
                imports.append("realworld.detail.{}.{}".format(profile, case))
                program = "//bazel/itest/goldens:validate.scm"
            else:
                program = "//bazel/itest/goldens:validate_contract.scm"
        _realworld_hurl_case_test(
            name = test_name,
            case = case,
            service = service,
            otel_sink = otel_sink,
            otel_app = otel_app,
            otel_libraries = libraries,
            otel_imports = imports,
            otel_program = program,
            otel_xfail = xfail_reason,
            flaky = flaky or bool(flaky_reason),
            tags = case_tags,
            **kwargs
        )
        tests.append(":" + test_name)
        if otel_sink and otel_exact and otel_candidates:
            candidate_name = test_name + "_golden_candidate"
            _realworld_hurl_case_test(
                name = candidate_name,
                case = case,
                service = service,
                otel_sink = otel_sink,
                otel_app = otel_app,
                otel_mode = "candidate",
                tags = tags + ["manual"],
                **kwargs
            )
            candidates.append(":" + candidate_name)
    native.test_suite(
        name = name,
        tests = tests,
        tags = tags,
    )
    if candidates:
        native.test_suite(
            name = name + "_golden_candidates",
            tests = candidates,
            tags = tags + ["manual"],
        )
