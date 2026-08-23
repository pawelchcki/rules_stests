"""Machine-updated OCI manifest locks for the RealWorld fixtures."""

OCI_IMAGES = {
    "django_ninja_realworld": struct(
        repository = "ghcr.io/hannah-barbera/rules-stests-django-ninja",
        digest = "sha256:834043d50b3cf629df546928e038614e4bee86160f072dfd34c7832eb1edf042",
        tree = "8d610bdbda2e5ec860e099f47073c18bb4ff75dd",
    ),
    "fastapi_realworld": struct(
        repository = "ghcr.io/hannah-barbera/rules-stests-fastapi-realworld",
        digest = "sha256:9eecccedf1b0800c02659d8c22140bc7a3a46bdf2573b296afb578d7b8a89aa9",
        tree = "2487f52943eba94198073dd0cdc5d99a554b5e08",
    ),
}
