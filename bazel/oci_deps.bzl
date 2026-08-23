"""Creates repositories for the digest-locked RealWorld app images."""

load("@rules_oci//oci:pull.bzl", "oci_pull")
load("//bazel:oci_images.lock.bzl", "OCI_IMAGES")

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

    return module_ctx.extension_metadata(
        root_module_direct_deps = direct_deps,
        root_module_direct_dev_deps = [],
        reproducible = True,
    )

oci_deps = module_extension(implementation = _oci_deps_impl)
