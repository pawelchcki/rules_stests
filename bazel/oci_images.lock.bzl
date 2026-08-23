"""Machine-updated OCI manifest locks for the RealWorld fixtures."""

HURL_TOOL = struct(
    repository = "ghcr.io/orange-opensource/hurl",
    digest = "sha256:0c153999ee81f11d842bd0afb9f209673f944007aec93d6cf100122f4f606769",
    version = "8.0.1",
)

OCI_IMAGES = {
    "django_ninja_realworld": struct(
        repository = "ghcr.io/pawelchcki/rules_stest_apps",
        digest = "sha256:627096d6223dcdc8507213594a46df4960e4eadce80c3eb1de3920e0f02ddd14",
        tree = "948d532d56d8266a7fffd9feac8713d1bfbb728a",
    ),
    "aiohttp_realworld": struct(
        repository = "ghcr.io/pawelchcki/rules_stest_apps",
        digest = "sha256:419592d322bda33e2df671d44fa47443f431e2d1d1ded34c1821b16f9448aa00",
        tree = "41bdcadbd7c0ae3f61321cf19c1e0b7a22940589",
    ),
}
