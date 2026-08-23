"""Machine-updated OCI manifest locks for the RealWorld fixtures."""

OCI_IMAGES = {
    "django_ninja_realworld": struct(
        repository = "ghcr.io/hannah-barbera/rules-stests-django-ninja",
        digest = "sha256:cd7539892d8847145c3fcc0a8c0894cb290d56cf5248da45c55d63e2eea6d1d3",
        tree = "d1b79c7c760c757661221477071e3582561c280a",
    ),
    "fastapi_realworld": struct(
        repository = "ghcr.io/hannah-barbera/rules-stests-fastapi-realworld",
        digest = "sha256:79963a9c183e536c26d4834d02b54c7ae8e027a680677e163ee21302d05d08fb",
        tree = "3a464e50be8778d5463e99ad599614f25f0599a3",
    ),
}
