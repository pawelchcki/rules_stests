"""Cacheable OCI-to-rootfs materialization for integration-test tools and apps."""

def _oci_rootfs_impl(ctx):
    image_files = ctx.attr.image[DefaultInfo].files
    image_file_list = image_files.to_list()
    if len(image_file_list) != 1:
        fail("image must provide exactly one OCI layout directory")

    zstd = ctx.toolchains["@aspect_bazel_lib//lib:zstd_toolchain_type"].zstdinfo.binary
    rootfs = ctx.actions.declare_directory(ctx.label.name)
    args = ctx.actions.args()
    args.add(image_file_list[0].path)
    args.add(rootfs.path)
    args.add("single" if ctx.attr.single_payload else "multi")
    args.add(zstd.path)
    ctx.actions.run(
        arguments = [args],
        executable = ctx.executable._extractor,
        inputs = image_files,
        mnemonic = "OciRootfs",
        outputs = [rootfs],
        progress_message = "Materializing cached OCI rootfs %{label}",
        tools = [ctx.executable._extractor, zstd],
    )
    return [
        DefaultInfo(
            files = depset([rootfs]),
            runfiles = ctx.runfiles(files = [rootfs]),
        ),
    ]

oci_rootfs = rule(
    implementation = _oci_rootfs_impl,
    toolchains = ["@aspect_bazel_lib//lib:zstd_toolchain_type"],
    attrs = {
        "image": attr.label(mandatory = True),
        "single_payload": attr.bool(default = False),
        "_extractor": attr.label(
            cfg = "exec",
            default = Label("//harness:oci_rootfs_extract"),
            executable = True,
        ),
    },
)
