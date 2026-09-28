"""Single source of truth for the executable telemetry corpus."""

# Scenarios that come from the pinned upstream RealWorld API spec archive.
REALWORLD_UPSTREAM_HURL_CASES = [
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

# Scenarios this repository owns, because they exercise telemetry behaviour
# the upstream API conformance suite has no reason to cover.
REALWORLD_LOCAL_HURL_CASES = {
    "propagation": Label("//corpus:realworld/hurl/propagation.hurl"),
    "propagation_b3": Label("//corpus:realworld/hurl/propagation_b3.hurl"),
    "propagation_datadog": Label("//corpus:realworld/hurl/propagation_datadog.hurl"),
    "unicode": Label("//corpus:realworld/hurl/unicode.hurl"),
}

# Scenarios that need a particular propagator or telemetry family, so only the
# profile configured for them runs them.
REALWORLD_VARIANT_HURL_CASES = ["propagation_b3", "propagation_datadog"]

# What every profile runs unless it says otherwise.
REALWORLD_BASE_HURL_CASES = REALWORLD_UPSTREAM_HURL_CASES + sorted([
    case
    for case in REALWORLD_LOCAL_HURL_CASES
    if case not in REALWORLD_VARIANT_HURL_CASES
])

REALWORLD_HURL_CASES = REALWORLD_UPSTREAM_HURL_CASES + sorted(REALWORLD_LOCAL_HURL_CASES)

# Stak requires libraries to be defined before a program imports them. Keep this
# list dependency ordered; it is shared by profile manifests and the sink probe.
OTEL_CORE_LIBRARIES = [
    "telemetry/contract-error.scm",
    "otel/base.scm",
    "otel/text.scm",
    "otel/identifiers.scm",
    "otel/record.scm",
    "otel/contract-error.scm",
    "otel/matchers.scm",
    "otel/declarations.scm",
    "otel/validation.scm",
    "otel/trace-shape.scm",
    "otel/trace-shape/explain.scm",
    "otel/trace-shape/match.scm",
    "otel/capture/shapes.scm",
    "otel/proofs/traces.scm",
    "otel/proofs/metrics.scm",
    "otel/proofs/logs.scm",
    "otel/proofs/resource.scm",
    "otel/proofs/exporters.scm",
    "otel/proofs/environment.scm",
    "otel/proofs/propagation.scm",
    "otel/proofs.scm",
    "realworld/route.scm",
    "realworld/scenarios.scm",
    "realworld/contract.scm",
    "otel/profile.scm",
]

OTEL_PROFILES = {
    "go-gin-otelbuild-v1-1-0": struct(
        runtime = "otel/runtime/go-otelbuild-v1-1-0.scm",
        implementations = [
            "otel/implementation/go-compile-v1.1.0.scm",
            "otel/implementation/go-runtime-v0.70.0.scm",
        ],
        signals = ["traces", "metrics"],
    ),
    "python-aiohttp-auto-v0-65b0": struct(
        runtime = "otel/runtime/python-auto-v0-65b0.scm",
        implementations = [
            "otel/implementation/python-sdk-v1.44.0.scm",
            "otel/implementation/python-auto-v0.65b0.scm",
            "otel/implementation/aiohttp-v0.65b0.scm",
        ],
        signals = ["traces", "metrics", "logs"],
    ),
    "python-django-auto-v0-65b0": struct(
        runtime = "otel/runtime/python-auto-v0-65b0.scm",
        parts = ["realworld/profile/parts/python-django-auto-v0-65b0.scm"],
        implementations = [
            "otel/implementation/python-sdk-v1.44.0.scm",
            "otel/implementation/python-auto-v0.65b0.scm",
            "otel/implementation/django-v0.65b0.scm",
        ],
        signals = ["traces", "metrics", "logs"],
    ),
    "python-django-auto-v0-65b0-temporality-delta": struct(
        runtime = "otel/runtime/python-auto-v0-65b0.scm",
        parts = ["realworld/profile/parts/python-django-auto-v0-65b0.scm"],
        implementations = [
            "otel/implementation/python-sdk-v1.44.0.scm",
            "otel/implementation/python-auto-v0.65b0.scm",
            "otel/implementation/django-v0.65b0.scm",
        ],
        signals = ["traces", "metrics", "logs"],
        # One scenario is enough: the variable changes how every metric point is
        # reported, not what any particular request produces.
        scenarios = ["tags"],
    ),
    "python-django-auto-v0-65b0-propagators-b3": struct(
        runtime = "otel/runtime/python-auto-v0-65b0.scm",
        parts = ["realworld/profile/parts/python-django-auto-v0-65b0.scm"],
        implementations = [
            "otel/implementation/python-sdk-v1.44.0.scm",
            "otel/implementation/python-auto-v0.65b0.scm",
            "otel/implementation/django-v0.65b0.scm",
        ],
        signals = ["traces", "metrics", "logs"],
        scenarios = ["propagation_b3"],
    ),
    "python-django-auto-v0-65b0-span-limits": struct(
        runtime = "otel/runtime/python-auto-v0-65b0.scm",
        parts = ["realworld/profile/parts/python-django-auto-v0-65b0.scm"],
        implementations = [
            "otel/implementation/python-sdk-v1.44.0.scm",
            "otel/implementation/python-auto-v0.65b0.scm",
            "otel/implementation/django-v0.65b0.scm",
        ],
        signals = ["traces", "metrics", "logs"],
        scenarios = ["tags"],
    ),
    "ruby-rails-auto-v0-1-0": struct(
        runtime = "otel/runtime/ruby-auto-v0-1-0.scm",
        implementations = [
            "otel/implementation/rails-v0.40.0.scm",
            "otel/implementation/ruby-auto-v0.1.0.scm",
            "otel/implementation/ruby-sdk-v1.11.0.scm",
        ],
        signals = ["traces", "logs"],
    ),
}

def declare_otel_profiles(otel_realworld_profile):
    """Declares every registered profile and its normalized proof-plan view."""
    for profile_id, declaration in OTEL_PROFILES.items():
        # A variant profile shares its base profile's contract through a parts
        # library, which has to be defined before the profile that imports it.
        parts = getattr(declaration, "parts", [])
        scenarios = getattr(declaration, "scenarios", None)
        otel_realworld_profile(
            name = profile_id,
            specification = "realworld/profile/{}.scm".format(profile_id),
            implementation_libraries = declaration.implementations,
            runtime_libraries = [declaration.runtime] + parts,
            shape_root = "realworld/shape/{}".format(profile_id),
            signals = declaration.signals,
            scenarios = scenarios if scenarios else REALWORLD_BASE_HURL_CASES,
            standard_registry = ":otel_standard_registry",
        )

# Datadog has a separate wire feature catalog and proof runtime. The shared
# scenario observations describe application HTTP behavior, not telemetry.
# Every list is dependency ordered, like OTEL_CORE_LIBRARIES.

# Named capture assertions, one library per theme, then their registry.
DATADOG_CAPTURE_LIBRARIES = [
    "telemetry/contract-error.scm",
    "datadog/capture/base.scm",
    "datadog/capture/intake.scm",
    "datadog/capture/traces.scm",
    "datadog/capture/service.scm",
    "datadog/capture/sampling.scm",
    "datadog/capture/propagation.scm",
    "datadog/capture/http.scm",
    "datadog/capture/database.scm",
    "datadog/capture/errors.scm",
    "datadog/capture/coverage.scm",
    "datadog/capture/shapes.scm",
]

# Feature id -> assertion tables, one per theme, then their facade.
DATADOG_PROOF_LIBRARIES = [
    "datadog/proofs/intake.scm",
    "datadog/proofs/traces.scm",
    "datadog/proofs/service.scm",
    "datadog/proofs/sampling.scm",
    "datadog/proofs/propagation.scm",
    "datadog/proofs/http.scm",
    "datadog/proofs/database.scm",
    "datadog/proofs/errors.scm",
    "datadog/proofs/coverage.scm",
    "datadog/proofs.scm",
]

# The vocabulary reviewed trace shapes are written in: the shape language and
# its matcher, what each tracer adds, and one library per application.
DATADOG_SHAPE_LIBRARIES = [
    "datadog/trace-shape.scm",
    "datadog/trace-shape/match.scm",
    "datadog/shape/tracers.scm",
    "datadog/shape/http.scm",
    "datadog/shape/aiohttp.scm",
    "datadog/shape/django.scm",
    "datadog/shape/rails.scm",
    "datadog/shape/gin.scm",
]

DATADOG_CORE_LIBRARIES = DATADOG_CAPTURE_LIBRARIES + DATADOG_PROOF_LIBRARIES + DATADOG_SHAPE_LIBRARIES + [
    "realworld/scenarios.scm",
    "datadog/profile.scm",
]

def datadog_library_args(libraries):
    """Command-line paths for libraries in their dependency order.

    `$(rootpaths)` sorts a filegroup's files, so tests that assemble a Scheme
    bundle receive one `$(rootpath)` per library instead.
    """
    return ["$(rootpath {})".format(label) for label in datadog_library_labels(libraries)]

def datadog_library_labels(libraries):
    """The labels datadog_library_args refers to; list them as test data."""
    return ["//corpus:{}".format(path) for path in libraries]

DATADOG_SCENARIOS = REALWORLD_BASE_HURL_CASES + ["propagation_datadog"]

# Each profile's reviewed shapes are datadog/realworld/shape/<profile>/<scenario>.scm.
DATADOG_PROFILES = {
    "go-gin-datadog-v2-10-1-v04": struct(implementation = "go-v2.10.1", wire_version = "v0.4"),
    "ruby-rails-datadog-v2-42-0-v04": struct(implementation = "ruby-v2.42.0", wire_version = "v0.4"),
    "python-aiohttp-datadog-v4-14-0-v05": struct(implementation = "python-v4.14.0", wire_version = "v0.5"),
    "python-django-datadog-v4-14-0-v05": struct(implementation = "python-v4.14.0", wire_version = "v0.5"),
    "python-aiohttp-datadog-v4-14-0-v04": struct(implementation = "python-v4.14.0", wire_version = "v0.4"),
    "python-django-datadog-v4-14-0-v04": struct(implementation = "python-v4.14.0", wire_version = "v0.4"),
}

def declare_datadog_profiles(datadog_realworld_profile):
    """Declares Datadog's independent profiles and native wire assertions."""
    for profile_id, declaration in DATADOG_PROFILES.items():
        datadog_realworld_profile(
            name = profile_id,
            specification = "datadog/realworld/profile/{}.scm".format(profile_id),
            implementation_libraries = ["datadog/implementation/{}.scm".format(declaration.implementation)],
            runtime_libraries = [],
            # Until its candidates are reviewed, a profile validates contracts only.
            shape_root = "datadog/realworld/shape/{}".format(profile_id) if getattr(declaration, "reviewed", True) else None,
            signals = ["traces"],
            scenarios = DATADOG_SCENARIOS,
            wire_version = declaration.wire_version,
        )
