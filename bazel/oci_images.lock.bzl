"""Machine-updated OCI manifest locks for the RealWorld fixtures."""

OCI_IMAGES = {
    "django_ninja_realworld": struct(
        repository = "ghcr.io/hannah-barbera/rules-stests-django-ninja",
        digest = "sha256:0000000000000000000000000000000000000000000000000000000000000000",
        tree = "unpublished",
    ),
    "fastapi_realworld": struct(
        repository = "ghcr.io/hannah-barbera/rules-stests-fastapi-realworld",
        digest = "sha256:0000000000000000000000000000000000000000000000000000000000000000",
        tree = "unpublished",
    ),
}
