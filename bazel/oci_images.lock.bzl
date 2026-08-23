"""Machine-updated OCI manifest locks for the RealWorld fixtures."""

OCI_IMAGES = {
    "django_ninja_realworld": struct(
        repository = "ghcr.io/hannah-barbera/rules-stests-django-ninja",
        digest = "sha256:0bdb08ba2c8b55e53d31c1b384430f1b7064c3e5a18d7e7dc8dea7d4bdcb0be3",
        tree = "3bae9d337d95dd6f576d23de93000abb9451cb15",
    ),
    "fastapi_realworld": struct(
        repository = "ghcr.io/hannah-barbera/rules-stests-fastapi-realworld",
        digest = "sha256:e3b1519f328127eb3833c0a35b37a1b5b379872074540cd146e3c40d017e35ed",
        tree = "bbfa33123514ec450ea128bd6f40470bb46ea846",
    ),
}
