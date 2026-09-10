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
DATADOG_CORE_LIBRARIES = [
    "telemetry/contract-error.scm",
    "datadog/capture/shapes.scm",
    "datadog/proofs.scm",
    "datadog/trace-shape.scm",
    "realworld/scenarios.scm",
    "datadog/profile.scm",
]

DATADOG_PROFILES = {
    "python-aiohttp-datadog-v4-14-0-v05": struct(application = "aiohttp", wire_version = "v0.5", scenarios = REALWORLD_BASE_HURL_CASES + ["propagation_datadog"]),
    "python-django-datadog-v4-14-0-v05": struct(application = "django", wire_version = "v0.5", scenarios = REALWORLD_BASE_HURL_CASES + ["propagation_datadog"]),
    "python-aiohttp-datadog-v4-14-0-v04": struct(application = "aiohttp", wire_version = "v0.4", scenarios = ["tags"]),
    "python-django-datadog-v4-14-0-v04": struct(application = "django", wire_version = "v0.4", scenarios = ["tags"]),
}

# Exact expectations are enabled incrementally as their stack layer lands.
DATADOG_REVIEWED_SHAPES = [
    "datadog/realworld/shape/python-aiohttp-datadog-v4-14-0-v04/tags.scm",
    "datadog/realworld/shape/python-aiohttp-datadog-v4-14-0-v05/articles.scm",
    "datadog/realworld/shape/python-aiohttp-datadog-v4-14-0-v05/auth.scm",
    "datadog/realworld/shape/python-aiohttp-datadog-v4-14-0-v05/comments.scm",
    "datadog/realworld/shape/python-aiohttp-datadog-v4-14-0-v05/errors_articles.scm",
    "datadog/realworld/shape/python-aiohttp-datadog-v4-14-0-v05/errors_auth.scm",
    "datadog/realworld/shape/python-aiohttp-datadog-v4-14-0-v05/errors_authorization.scm",
    "datadog/realworld/shape/python-aiohttp-datadog-v4-14-0-v05/errors_comments.scm",
    "datadog/realworld/shape/python-aiohttp-datadog-v4-14-0-v05/errors_profiles.scm",
    "datadog/realworld/shape/python-aiohttp-datadog-v4-14-0-v05/favorites.scm",
    "datadog/realworld/shape/python-aiohttp-datadog-v4-14-0-v05/feed.scm",
    "datadog/realworld/shape/python-aiohttp-datadog-v4-14-0-v05/pagination.scm",
    "datadog/realworld/shape/python-aiohttp-datadog-v4-14-0-v05/profiles.scm",
    "datadog/realworld/shape/python-aiohttp-datadog-v4-14-0-v05/propagation.scm",
    "datadog/realworld/shape/python-aiohttp-datadog-v4-14-0-v05/propagation_datadog.scm",
    "datadog/realworld/shape/python-aiohttp-datadog-v4-14-0-v05/tags.scm",
    "datadog/realworld/shape/python-aiohttp-datadog-v4-14-0-v05/unicode.scm",
    "datadog/realworld/shape/python-django-datadog-v4-14-0-v04/tags.scm",
    "datadog/realworld/shape/python-django-datadog-v4-14-0-v05/articles.scm",
    "datadog/realworld/shape/python-django-datadog-v4-14-0-v05/auth.scm",
    "datadog/realworld/shape/python-django-datadog-v4-14-0-v05/feed.scm",
    "datadog/realworld/shape/python-django-datadog-v4-14-0-v05/pagination.scm",
    "datadog/realworld/shape/python-django-datadog-v4-14-0-v05/profiles.scm",
    "datadog/realworld/shape/python-django-datadog-v4-14-0-v05/propagation.scm",
    "datadog/realworld/shape/python-django-datadog-v4-14-0-v05/propagation_datadog.scm",
    "datadog/realworld/shape/python-django-datadog-v4-14-0-v05/tags.scm",
    "datadog/realworld/shape/python-django-datadog-v4-14-0-v05/unicode.scm",
]

def declare_datadog_profiles(datadog_realworld_profile):
    """Declares Datadog's independent profiles and native wire assertions."""
    for profile_id, declaration in DATADOG_PROFILES.items():
        datadog_realworld_profile(
            name = profile_id,
            specification = "datadog/realworld/profile/{}.scm".format(profile_id),
            implementation_libraries = ["datadog/implementation/python-v4.14.0.scm"],
            runtime_libraries = [],
            scenario_shapes = {
                path.rsplit("/", 1)[1][:-4]: path
                for path in DATADOG_REVIEWED_SHAPES
                if path.startswith("datadog/realworld/shape/{}/".format(profile_id))
            },
            signals = ["traces"],
            scenarios = declaration.scenarios,
            wire_version = declaration.wire_version,
        )
