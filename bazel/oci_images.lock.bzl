"""Machine-updated OCI manifest locks for the RealWorld fixtures."""

HURL_TOOL = struct(
    repository = "ghcr.io/orange-opensource/hurl",
    digest = "sha256:0c153999ee81f11d842bd0afb9f209673f944007aec93d6cf100122f4f606769",
    version = "8.0.1",
)

OCI_IMAGES = {
    "django_ninja_realworld": struct(
        repository = "ghcr.io/pawelchcki/rules_stest_apps",
        digest = "sha256:09992360b1d3cbf1ffd951aa043553ec3e0d4a77aee6421d43b00fb40b2b0e89",
        tree = "948d532d56d8266a7fffd9feac8713d1bfbb728a",
    ),
    "aiohttp_realworld": struct(
        repository = "ghcr.io/pawelchcki/rules_stest_apps",
        digest = "sha256:0559e2c00ed7339a69f2fdb4d2bb57e2eab60b42f15e67e86d4a88d4061d7235",
        tree = "41bdcadbd7c0ae3f61321cf19c1e0b7a22940589",
    ),
}
