"""Creates repositories for the digest-locked RealWorld app images."""

load("@rules_oci//oci:pull.bzl", "oci_pull")
load("//bazel:oci_images.lock.bzl", "HURL_TOOL", "OCI_IMAGES", "OTEL_PYTHON", "OTEL_RUBY")

def _oci_deps_impl(module_ctx):
    direct_deps = []
    for name, image in OCI_IMAGES.items():
        oci_pull(
            name = name,
            image = image.repository,
            digest = image.digest,
            platforms = ["linux/amd64"],
            is_bzlmod = True,
        )
        direct_deps.extend([name, name + "_linux_amd64"])

    oci_pull(
        name = "hurl_tool",
        image = HURL_TOOL.repository,
        digest = HURL_TOOL.digest,
        platforms = ["linux/amd64"],
        is_bzlmod = True,
    )
    direct_deps.extend(["hurl_tool", "hurl_tool_linux_amd64"])

    oci_pull(
        name = "otel_python",
        image = OTEL_PYTHON.repository,
        digest = OTEL_PYTHON.digest,
        platforms = ["linux/amd64"],
        is_bzlmod = True,
    )
    direct_deps.extend(["otel_python", "otel_python_linux_amd64"])

    oci_pull(
        name = "otel_ruby",
        image = OTEL_RUBY.repository,
        digest = OTEL_RUBY.digest,
        platforms = ["linux/amd64"],
        is_bzlmod = True,
    )
    direct_deps.extend(["otel_ruby", "otel_ruby_linux_amd64"])

    return module_ctx.extension_metadata(
        root_module_direct_deps = direct_deps,
        root_module_direct_dev_deps = [],
        reproducible = True,
    )

oci_deps = module_extension(implementation = _oci_deps_impl)
