"""Machine-updated OCI manifest locks for the RealWorld fixtures."""

OCI_IMAGES = {
    "django_ninja_realworld": struct(
        repository = "ghcr.io/hannah-barbera/rules-stests-django-ninja",
        digest = "sha256:834043d50b3cf629df546928e038614e4bee86160f072dfd34c7832eb1edf042",
        tree = "8d610bdbda2e5ec860e099f47073c18bb4ff75dd",
    ),
    "fastapi_realworld": struct(
        repository = "ghcr.io/hannah-barbera/rules-stests-fastapi-realworld",
        digest = "sha256:2cdb62898b47e64f1f97fa82e184b2a1c9e77ce52b043ccbe2e2efd4abd8c350",
        tree = "bbfa33123514ec450ea128bd6f40470bb46ea846",
    ),
}
