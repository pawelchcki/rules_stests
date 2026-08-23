"""Machine-updated OCI manifest locks for the RealWorld fixtures."""

HURL_TOOL = struct(
    repository = "ghcr.io/orange-opensource/hurl",
    digest = "sha256:0c153999ee81f11d842bd0afb9f209673f944007aec93d6cf100122f4f606769",
    version = "8.0.1",
)

OCI_IMAGES = {
    "django_ninja_realworld": struct(
        repository = "ghcr.io/pawelchcki/rules-stests-django-ninja",
        digest = "sha256:786e4361b6f91f4a1212671a588b8567972588bfcbe19bd90f2b137249ffb06e",
        tree = "948d532d56d8266a7fffd9feac8713d1bfbb728a",
    ),
    "aiohttp_realworld": struct(
        repository = "ghcr.io/pawelchcki/rules-stests-aiohttp",
        digest = "sha256:44d534b8e0c68adb4ec38c5d596373a5a4f43e24a1aef5bee4646360667000a4",
        tree = "41bdcadbd7c0ae3f61321cf19c1e0b7a22940589",
    ),
}
