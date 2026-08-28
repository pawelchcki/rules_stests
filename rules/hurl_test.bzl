"""Sharded RealWorld Hurl contract tests for rules_itest services."""

load("@rules_itest//:itest.bzl", "service_test")
load(
    "//corpus:defs.bzl",
    _CASES = "REALWORLD_HURL_CASES",
    _contract_bundle = "contract_bundle",
    _exact_bundle = "exact_bundle",
    _profile_library = "profile_library",
)

# Labels resolved in this module's repository. `service_test` args go through
# Bazel's native location expansion, which resolves labels in the *consumer's*
# repo mapping, so every label owned by this module must be a canonical `Label`.
_HURL_ROOTFS = Label("//bazel/itest:hurl_rootfs")
_DRIVER = Label("//bazel/itest:realworld_hurl")
_SPEC_ANCHOR = Label("@realworld_api_specs//:hurl_all")

# Re-exported for consumers that already load it from here.
REALWORLD_HURL_CASES = _CASES

def _rootpath(label):
    return "$(rootpath {})".format(str(label))

def _realworld_hurl_case_test(
        name,
        case,
        service,
        otel_sink = None,
        otel_app = None,
        otel_profile = None,
        otel_libraries = [],
        otel_imports = [],
        otel_program = None,
        otel_mode = "validate",
        otel_signals = None,
        otel_xfail = "",
        flaky = False,
        tags = [],
        **kwargs):
    spec = _SPEC_ANCHOR.same_package_label("hurl/{}.hurl".format(case))
    args = [
        "--service-suffix=" + service,
        "--jobs=1",
        "--hurl-rootfs=" + _rootpath(_HURL_ROOTFS),
    ]
    data = [
        _HURL_ROOTFS,
        spec,
    ]
    if otel_sink:
        args.extend([
            "--otel-sink-suffix=" + otel_sink,
            "--otel-mode=" + otel_mode,
            "--otel-case={}/{}".format(otel_app, case),
        ])
        if otel_signals:
            args.append("--otel-signals=" + ",".join(otel_signals))
        if otel_profile:
            args.append("--otel-profile=" + otel_profile)
        for library in otel_libraries:
            args.append("--otel-library=" + _rootpath(library))
        for library in otel_imports:
            args.append("--otel-import=" + library)
        if otel_program:
            args.append("--otel-program=" + _rootpath(otel_program))
            data.append(otel_program)
        if otel_xfail:
            args.append("--otel-xfail=" + otel_xfail)
        data.extend(otel_libraries)
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

def realworld_hurl_test_suite(
        name,
        service,
        otel_sink = None,
        otel_app = None,
        otel_profile = None,
        otel_profile_library = None,
        otel_runtime_libraries = None,
        otel_trace_shape_library_prefix = None,
        otel_signals = None,
        otel_exact = True,
        otel_candidates = True,
        otel_flaky_reason = "",
        otel_flaky_cases = {},
        otel_xfails = {},
        flaky = False,
        tags = [],
        **kwargs):
    """Creates one schedulable integration test per upstream Hurl file.

    OTLP validation selects a portable scenario from a shared library and
    combines it with a named implementation profile. Contract mode permits
    implementation-specific non-server spans.

    Args:
        name: name of the generated `test_suite`; each case test is `<name>_<case>`.
        service: the `itest_service` under test (consumer-relative label).
        otel_sink: OTLP sink service to validate against; enables OTLP checks.
        otel_app: short application name, used for candidate paths and the
            default profile. Required with `otel_sink`.
        otel_profile: implementation profile name; defaults to
            `python-<otel_app>-auto-v0-65b0`.
        otel_profile_library: overrides the profile `.scm`; defaults to the
            corpus profile library for `otel_profile`.
        otel_runtime_libraries: overrides the language-runtime `.scm` libraries.
        otel_trace_shape_library_prefix: overrides where per-case goldens live;
            the case name and `/golden.scm` are appended.
        otel_signals: OTLP signals the implementation exports; defaults to all
            three. Must agree with the profile's declared metric and log scopes.
        otel_exact: validate the exact trace shape against a checked-in golden.
        otel_candidates: also generate `manual` golden-candidate targets.
        otel_flaky_reason: marks every case flaky with this reason.
        otel_flaky_cases: per-case flaky reasons.
        otel_xfails: per-case expected-failure reasons.
        flaky: marks every generated test flaky.
        tags: tags applied to every generated target.
        **kwargs: forwarded to each `service_test`.
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

    profile = ""
    if otel_sink:
        profile = otel_profile or "python-{}-auto-v0-65b0".format(otel_app)
        if otel_profile_library == None:
            otel_profile_library = _profile_library(profile)

    tests = []
    candidates = []
    for case in REALWORLD_HURL_CASES:
        test_name = name + "_" + case
        xfail_reason = otel_xfails.get(case, "")
        if case in otel_xfails and not xfail_reason:
            fail("otel_xfails reason for {} must be non-empty".format(case))
        flaky_reason = otel_flaky_cases.get(case, otel_flaky_reason)
        if case in otel_flaky_cases and not flaky_reason:
            fail("otel_flaky_cases reason for {} must be non-empty".format(case))
        case_is_flaky = not xfail_reason and (flaky or bool(flaky_reason))
        case_tags = tags + (["otel-xfail"] if xfail_reason else []) + (["otel-flaky"] if case_is_flaky else [])
        libraries = []
        imports = []
        program = None
        contract = None
        if otel_sink:
            contract = _contract_bundle(
                profile,
                profile_library_label = otel_profile_library,
                runtime_libraries = otel_runtime_libraries,
            )
            if otel_exact:
                golden = None
                if otel_trace_shape_library_prefix:
                    golden = otel_trace_shape_library_prefix + case + "/golden.scm"
                bundle = _exact_bundle(
                    profile,
                    case,
                    golden_library_label = golden,
                    profile_library_label = otel_profile_library,
                    runtime_libraries = otel_runtime_libraries,
                )
            else:
                bundle = contract
            libraries = bundle.libraries
            imports = bundle.imports
            program = bundle.program
        _realworld_hurl_case_test(
            name = test_name,
            case = case,
            service = service,
            otel_sink = otel_sink,
            otel_app = otel_app,
            otel_profile = profile,
            otel_libraries = libraries,
            otel_imports = imports,
            otel_program = program,
            otel_signals = otel_signals,
            otel_xfail = xfail_reason,
            flaky = case_is_flaky,
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
                otel_profile = profile,
                otel_libraries = contract.libraries,
                otel_imports = contract.imports,
                otel_program = contract.program,
                otel_signals = otel_signals,
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
