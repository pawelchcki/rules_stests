"""Cached, parallel compilation of a probe's Scheme validation programs."""

def scheme_bytecode_bundles(name, probe, libraries, shards = 8):
    """Compiles a probe's programs into bytecode bundles at build time.

    Compiling a program recompiles the VM prelude, which costs seconds no matter
    how small the program is. The probe enumerates its programs (`--compile-to`
    with `--compile-shard`), so each of `shards` Bazel actions compiles a slice
    in parallel and the remote cache keeps the result until an input changes.

    Args:
      name: filegroup of the bundles.
      probe: probe binary accepting --compile-to, --compile-shard, --compiler,
        and the ordered library paths as positional arguments.
      libraries: ordered Scheme library labels passed to the probe.
      shards: number of parallel compilation actions.

    Returns:
      struct(args, data): test arguments naming every bundle with --bytecode,
      and the bundle labels to list as test data.
    """
    outputs = []
    for shard in range(shards):
        output = "{}.{}-of-{}.json".format(name, shard, shards)
        native.genrule(
            name = "{}_{}".format(name, shard),
            srcs = libraries,
            outs = [output],
            cmd = " ".join([
                "$(execpath {})".format(probe),
                "--compile-to=$@",
                "--compile-shard={}/{}".format(shard, shards),
                "--compiler=$(execpath //harness:telemetry_sink)",
            ] + ["$(execpath {})".format(library) for library in libraries]),
            tools = [probe, "//harness:telemetry_sink"],
        )
        outputs.append(":" + output)
    native.filegroup(name = name, srcs = outputs)
    return struct(
        args = ["--bytecode=$(rootpath {})".format(output) for output in outputs],
        data = outputs,
    )
