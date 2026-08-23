"""Machine-updated OCI manifest locks for the RealWorld fixtures."""

HURL_TOOL = struct(
    repository = "ghcr.io/orange-opensource/hurl",
    digest = "sha256:0c153999ee81f11d842bd0afb9f209673f944007aec93d6cf100122f4f606769",
    version = "8.0.1",
)

OCI_IMAGES = {
    "django_ninja_realworld": struct(
        repository = "ghcr.io/hannah-barbera/rules-stests-django-ninja",
        digest = "sha256:0b08de467aab53150be0a7b8e74a69518de0fc1e3aa041d90c7f066b8f933f7e",
        tree = "8d610bdbda2e5ec860e099f47073c18bb4ff75dd",
    ),
    "aiohttp_realworld": struct(
        repository = "ghcr.io/hannah-barbera/rules-stests-aiohttp",
        digest = "sha256:2441abb0178c21b36d06c90b68e227b0f15f68d93590f57c284ad53de3db7bf5",
        tree = "41bdcadbd7c0ae3f61321cf19c1e0b7a22940589",
    ),
}
