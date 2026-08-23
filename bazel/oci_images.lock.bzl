"""Machine-updated OCI manifest locks for the RealWorld fixtures."""

OCI_IMAGES = {
    "django_ninja_realworld": struct(
        repository = "ghcr.io/hannah-barbera/rules-stests-django-ninja",
        digest = "sha256:0b08de467aab53150be0a7b8e74a69518de0fc1e3aa041d90c7f066b8f933f7e",
        tree = "8d610bdbda2e5ec860e099f47073c18bb4ff75dd",
    ),
    "fastapi_realworld": struct(
        repository = "ghcr.io/hannah-barbera/rules-stests-fastapi-realworld",
        digest = "sha256:e3b1519f328127eb3833c0a35b37a1b5b379872074540cd146e3c40d017e35ed",
        tree = "bbfa33123514ec450ea128bd6f40470bb46ea846",
    ),
}
