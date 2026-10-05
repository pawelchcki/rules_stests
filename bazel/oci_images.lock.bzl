"""Machine-updated OCI manifest locks for the RealWorld fixtures."""

HURL_TOOL = struct(
    repository = "ghcr.io/orange-opensource/hurl",
    digest = "sha256:0c153999ee81f11d842bd0afb9f209673f944007aec93d6cf100122f4f606769",
    version = "8.0.1",
)

OTEL_PYTHON = struct(
    repository = "ghcr.io/open-telemetry/opentelemetry-operator/autoinstrumentation-python",
    digest = "sha256:aa6af684df0d1b5aa9d4c26a1926ed136b5391c40ee35d5f0f4ce7547252a7cf",
    version = "0.65b0-1",
)

# Publication workflows replace this syntactically valid sentinel before the
# manual Ruby integration targets are enabled.
OTEL_RUBY = struct(
    repository = "ghcr.io/pawelchcki/rules_stest_agents",
    digest = "sha256:537b7b34e27e6479cf943d6f503312e74f11ec78222763c82934b368c7d555d2",
    tree = "ad9770154c01419976abbd65721588ff68e78de0",
    version = "0.1.0",
)

OCI_IMAGES = {
    "falcon_realworld": struct(
        repository = "ghcr.io/pawelchcki/rules_stest_apps",
        digest = "sha256:cb33e3a413455659d7d107cdf015a46941d921539c7865b1bc0509c443c426b0",
        tree = "792881ec6bc8bb91e8e7f0ed2d45974006291808",
    ),
    "rails_realworld": struct(
        repository = "ghcr.io/pawelchcki/rules_stest_apps",
        digest = "sha256:ba5fafa30c4e0e76f06f65ae7981048a03d776eb5366602ddc02ecdcd1f6b88d",
        tree = "2ffcfd52d7541dce85d7b39e06afdc12359844ae",
    ),
    "gin_realworld": struct(
        repository = "ghcr.io/pawelchcki/rules_stest_apps",
        digest = "sha256:c98ad190e2750b9ca69f3d61f91058a85ee7a34077cb5a4177b84c5c3cb8c188",
        tree = "7009dfcd4d3c0d15df7a9d7c7d721d0708fc9b8b",
    ),
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

OTEL_RUBY_PUBLISHED = OTEL_RUBY.tree != "unpublished"
RUBY_IMAGES_PUBLISHED = OTEL_RUBY_PUBLISHED and OCI_IMAGES["rails_realworld"].tree != "unpublished"
