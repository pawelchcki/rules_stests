"""Machine-updated OCI manifest locks for the RealWorld fixtures."""

OCI_IMAGES = {
    "django_ninja_realworld": struct(
        repository = "ghcr.io/hannah-barbera/rules-stests-django-ninja",
        digest = "sha256:0bdb08ba2c8b55e53d31c1b384430f1b7064c3e5a18d7e7dc8dea7d4bdcb0be3",
        tree = "3bae9d337d95dd6f576d23de93000abb9451cb15",
    ),
    "fastapi_realworld": struct(
        repository = "ghcr.io/hannah-barbera/rules-stests-fastapi-realworld",
        digest = "sha256:9eecccedf1b0800c02659d8c22140bc7a3a46bdf2573b296afb578d7b8a89aa9",
        tree = "2487f52943eba94198073dd0cdc5d99a554b5e08",
    ),
}
