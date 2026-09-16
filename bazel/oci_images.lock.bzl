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
    "gin_datadog_realworld": struct(
        repository = "ghcr.io/pawelchcki/rules_stest_apps",
        digest = "sha256:ee6a879cae36694b99a967fc4ba62b797a269422bd80249f8c7939de07cd0166",
        tree = "unpublished",
    ),
    "rails_realworld": struct(
        repository = "ghcr.io/pawelchcki/rules_stest_apps",
        digest = "sha256:ba5fafa30c4e0e76f06f65ae7981048a03d776eb5366602ddc02ecdcd1f6b88d",
        tree = "2ffcfd52d7541dce85d7b39e06afdc12359844ae",
    ),
    "gin_realworld": struct(
        repository = "ghcr.io/pawelchcki/rules_stest_apps",
        digest = "sha256:b1307a57811bdb039739b98298613412f25bf69c6a3dc576589a908c12319a86",
        tree = "3e3c29c2f28bc232eba4d3911d0399abfb009b8e",
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

DATADOG_PYTHON = struct(
    repository = "install.datadoghq.com/apm-library-python-package",
    digest = "sha256:8276af62a8236cb92a3bd64710271b5f2a537cb586e4633d92f1742f3c4ff3a0",
    version = "4.14.0-1",
)

# Built locally; publication is tracked separately from the payload digest.
DATADOG_RUBY = struct(
    repository = "ghcr.io/pawelchcki/rules_stest_agents",
    digest = "sha256:534130a20451560dd3183355584916f3173bc8db7f97e20bd2de908f9d473be9",
    tree = "unpublished",
    version = "2.42.0",
)
