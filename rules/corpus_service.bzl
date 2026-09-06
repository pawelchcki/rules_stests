"""Corpus-independent services from Bazel executables or materialized apps."""

load("@rules_itest//:itest.bzl", "itest_service")

_LAUNCHER = Label("//harness:app_launcher")

def corpus_service(
        name,
        rootfs = None,
        runtime = None,
        instance = None,
        command = None,
        args = [],
        injection = None,
        data = [],
        exe = None,
        **kwargs):
    """Launches an app as a rules_itest service within the Bazel test action.

    Supply either exe for a Bazel-built service or rootfs/runtime/instance/
    command for a materialized application. Extraction is a separate build
    action. Test protocols and corpus-specific assertions belong to callers.

    Args:
        name: Name of the itest_service target.
        rootfs: Materialized app directory label; mutually exclusive with exe.
        runtime: "python", "ruby" or "native" for the bundled runtime adapter.
        instance: Lowercase letters, digits, hyphens and underscores; identifies
            writable state under TEST_TMPDIR/rules_stests/<instance>/state.
        command: Python/Rails command, or rootfs-relative native binary.
        args: App arguments, including rules_itest substitutions such as $${PORT}.
        injection: Optional struct with rootfs and flags, as returned by
            otel_injection, python_auto_injection or ruby_auto_injection.
        data: Additional service runfiles.
        exe: Bazel executable label. Receives args, env and data directly,
            without rootfs/runtime setup or corpus-specific state preparation.
        **kwargs: itest_service options, including env, deps, health checks,
            port assignment and shutdown timeout.
    """
    if exe != None:
        if rootfs != None or runtime != None or instance != None or command != None or injection != None:
            fail("exe cannot be combined with rootfs, runtime, instance, command or injection")
        itest_service(name = name, exe = exe, args = args, data = data, **kwargs)
        return
    if rootfs == None:
        fail("provide either exe or rootfs with runtime, instance and command")
    if runtime not in ["python", "ruby", "native"]:
        fail("runtime must be python, ruby or native")
    if not instance or [c for c in instance.elems() if c not in "abcdefghijklmnopqrstuvwxyz0123456789-_"]:
        fail("instance must contain only lowercase letters, digits, hyphens and underscores")
    if not command:
        fail("command must be non-empty")
    launcher_args = [
        "--runtime=" + runtime,
        "--instance=" + instance,
        "--rootfs=$(rlocationpath {})".format(rootfs),
    ]
    launcher_data = data + [rootfs]
    if injection:
        launcher_args.extend(injection.flags)
        launcher_data.append(injection.rootfs)
    itest_service(
        name = name,
        exe = _LAUNCHER,
        args = launcher_args + ["--", command] + args,
        data = launcher_data,
        **kwargs
    )
