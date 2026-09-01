"""Stable identities for the RealWorld OpenTelemetry corpus."""

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
    "ruby-rails-auto-v0-1-0",
]

REALWORLD_PROFILE_TARGETS = {
    "go-gin-otelbuild-v1-1-0": Label("//corpus:go_gin_profile"),
    "python-aiohttp-auto-v0-65b0": Label("//corpus:python_aiohttp_profile"),
    "python-django-auto-v0-65b0": Label("//corpus:python_django_profile"),
    "ruby-rails-auto-v0-1-0": Label("//corpus:ruby_rails_profile"),
}
