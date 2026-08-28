"""Data API for the OTLP contract corpus.

Every label is a `Label` object resolved in this module's repository, so the
values stay correct when the corpus is loaded from an external Bazel module.
Consumers that only want the data (their own runner, no `service_test`) can
read `contract_bundle` / `exact_bundle` and ignore `//rules`.
"""

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

REALWORLD_PROFILES = [
    "go-gin-otelbuild-v1-1-0",
    "python-aiohttp-auto-v0-65b0",
    "python-django-auto-v0-65b0",
]

OTEL_VALIDATION_LIB = Label("//corpus:otel/validation.scm")
TRACE_SHAPE_LIB = Label("//corpus:otel/trace_shape.scm")
REALWORLD_CONTRACT_LIB = Label("//corpus:realworld/contract.scm")
PYTHON_RUNTIME_LIB = Label("//corpus:realworld/profiles/python.scm")
GO_RUNTIME_LIB = Label("//corpus:realworld/profiles/go.scm")
VALIDATE_PROGRAM = Label("//corpus:realworld/programs/validate.scm")
VALIDATE_CONTRACT_PROGRAM = Label("//corpus:realworld/programs/validate_contract.scm")

def profile_library(profile):
    """Returns the Scheme library defining `(realworld profile <profile>)`.

    Args:
        profile: implementation profile name, e.g. `python-django-auto-v0-65b0`.

    Returns:
        A `Label` for the profile's `.scm` source.
    """
    return PYTHON_RUNTIME_LIB.same_package_label("realworld/profiles/{}.scm".format(profile))

def golden_library(profile, case):
    """Returns the Scheme library defining `(realworld detail <profile> <case>)`.

    Args:
        profile: implementation profile name.
        case: RealWorld scenario name, one of `REALWORLD_HURL_CASES`.

    Returns:
        A `Label` for the case's checked-in `golden.scm`.
    """
    return PYTHON_RUNTIME_LIB.same_package_label(
        "realworld/goldens/{}/{}/golden.scm".format(profile, case),
    )

def contract_bundle(profile, profile_library_label = None, runtime_libraries = None):
    """Libraries and imports for portable (implementation-agnostic) validation.

    Args:
        profile: implementation profile name.
        profile_library_label: overrides the profile `.scm`; defaults to
            `profile_library(profile)`. May be a consumer-relative label string.
        runtime_libraries: overrides the language-runtime libraries; defaults to
            the runtime matching the selected public profile.

    Returns:
        A struct with `libraries` (labels) and `imports` (Scheme library names).
    """
    if profile_library_label == None:
        profile_library_label = profile_library(profile)
    if runtime_libraries == None:
        runtime_libraries = [GO_RUNTIME_LIB] if profile.startswith("go-") else [PYTHON_RUNTIME_LIB]
    return struct(
        libraries = [
            OTEL_VALIDATION_LIB,
            REALWORLD_CONTRACT_LIB,
        ] + list(runtime_libraries) + [profile_library_label],
        imports = [
            "otel.validation",
            "realworld.contract",
            "realworld.scenarios",
            "realworld.profile.{}".format(profile),
        ],
        program = VALIDATE_CONTRACT_PROGRAM,
    )

def exact_bundle(profile, case, golden_library_label = None, **kwargs):
    """Contract bundle plus the checked-in exact trace shape for one case.

    Args:
        profile: implementation profile name.
        case: RealWorld scenario name.
        golden_library_label: overrides the golden `.scm`; defaults to
            `golden_library(profile, case)`.
        **kwargs: forwarded to `contract_bundle`.

    Returns:
        A struct with `libraries`, `imports` and the exact-validation `program`.
    """
    base = contract_bundle(profile, **kwargs)
    if golden_library_label == None:
        golden_library_label = golden_library(profile, case)
    return struct(
        libraries = base.libraries + [TRACE_SHAPE_LIB, golden_library_label],
        imports = base.imports + [
            "otel.trace-shape",
            "realworld.detail.{}.{}".format(profile, case),
        ],
        program = VALIDATE_PROGRAM,
    )
