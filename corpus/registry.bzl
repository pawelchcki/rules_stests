"""Single source of truth for the executable OpenTelemetry corpus."""

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

# Scenarios this repository owns, because they exercise OpenTelemetry behaviour
# the upstream API conformance suite has no reason to cover.
REALWORLD_LOCAL_HURL_CASES = {
    "propagation": Label("//corpus:realworld/hurl/propagation.hurl"),
    "unicode": Label("//corpus:realworld/hurl/unicode.hurl"),
}

REALWORLD_HURL_CASES = REALWORLD_UPSTREAM_HURL_CASES + sorted(REALWORLD_LOCAL_HURL_CASES)

# Stak requires libraries to be defined before a program imports them. Keep this
# list dependency ordered; it is shared by profile manifests and the sink probe.
OTEL_CORE_LIBRARIES = [
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
            scenarios = scenarios if scenarios else REALWORLD_HURL_CASES,
            standard_registry = ":otel_standard_registry",
        )
