"""Small, independently cached Ruby runtime, native-gem and app actions."""

load("@rules_cc//cc:action_names.bzl", "ACTION_NAMES")
load("@rules_cc//cc:find_cc_toolchain.bzl", "find_cc_toolchain", "use_cc_toolchain")
load("@rules_cc//cc/common:cc_common.bzl", "cc_common")

_RubyNativeObjectsInfo = provider("PIC objects shared between Ruby extension link actions.", fields = {"files": "Compiled PIC object files."})

def _runtime_impl(ctx):
    image = ctx.attr.image[DefaultInfo].files.to_list()
    if len(image) != 1:
        fail("expected one OCI layout")
    root = ctx.actions.declare_directory(ctx.label.name)
    zstd = ctx.toolchains["@aspect_bazel_lib//lib:zstd_toolchain_type"].zstdinfo.binary
    ctx.actions.run(
        executable = ctx.executable._extractor,
        arguments = [image[0].path, root.path, "ruby-runtime", zstd.path],
        inputs = image,
        tools = [ctx.executable._extractor, zstd],
        outputs = [root],
        mnemonic = "RubyRuntime",
    )
    return [DefaultInfo(files = depset([root]), runfiles = ctx.runfiles(files = [root]))]

ruby_runtime = rule(
    implementation = _runtime_impl,
    attrs = {
        "image": attr.label(mandatory = True),
        "_extractor": attr.label(default = Label("//harness:oci_rootfs_extract"), executable = True, cfg = "exec"),
    },
    toolchains = ["@aspect_bazel_lib//lib:zstd_toolchain_type"],
)

def _compile(ctx, defines, includes, extra_inputs):
    toolchain = find_cc_toolchain(ctx)
    features = cc_common.configure_features(ctx = ctx, cc_toolchain = toolchain, requested_features = ctx.features, unsupported_features = ctx.disabled_features)

    # Historical gems pass Ruby VALUE words as opaque C pointers. Modern
    # Clang diagnoses these x86_64-compatible calls more strictly.
    _, outputs = cc_common.compile(
        name = ctx.label.name,
        actions = ctx.actions,
        cc_toolchain = toolchain,
        feature_configuration = features,
        srcs = ctx.files.srcs,
        public_hdrs = ctx.files.hdrs,
        includes = includes,
        defines = defines,
        additional_inputs = extra_inputs,
        disallow_nopic_outputs = True,
        user_compile_flags = [
            "-O2",
            "-g0",
            "-std=gnu99",
            "-Wno-incompatible-function-pointer-types",
            "-Wno-int-conversion",
            "-Wno-deprecated-declarations",
            "-Wno-compound-token-split-by-macro",
        ],
    )
    return toolchain, features, outputs.pic_objects

def _sqlite_impl(ctx):
    _, _, objects = _compile(ctx, ["SQLITE_THREADSAFE=1", "SQLITE_ENABLE_COLUMN_METADATA=1", "SQLITE_ENABLE_FTS5=1"], [], [])
    return [_RubyNativeObjectsInfo(files = objects), DefaultInfo(files = depset(objects))]

ruby_sqlite = rule(
    implementation = _sqlite_impl,
    attrs = {"srcs": attr.label_list(allow_files = True), "hdrs": attr.label_list(allow_files = True)},
    toolchains = use_cc_toolchain(),
    fragments = ["cpp"],
)

def _native_impl(ctx):
    root = ctx.attr.runtime[DefaultInfo].files.to_list()[0]
    headers = root.path + "/usr/local/include/ruby-" + ctx.attr.abi
    includes = [headers, headers + "/x86_64-linux", headers + "/x86_64-linux-gnu"] + [header.dirname for header in ctx.files.hdrs]
    defines = []
    if ctx.attr.sqlite:
        includes.extend([header.dirname for header in ctx.files.sqlite_headers])
        defines = [
            "HAVE_RUBY_ENCODING_H",
            "HAVE_RB_PROC_ARITY",
            "HAVE_SQLITE3_INITIALIZE",
            "HAVE_SQLITE3_BACKUP_INIT",
            "HAVE_SQLITE3_COLUMN_DATABASE_NAME",
            "HAVE_SQLITE3_ENABLE_LOAD_EXTENSION",
            "HAVE_SQLITE3_LOAD_EXTENSION",
            "HAVE_SQLITE3_OPEN_V2",
            "HAVE_SQLITE3_PREPARE_V2",
            "HAVE_TYPE_SQLITE3_INT64",
            "HAVE_TYPE_SQLITE3_UINT64",
            "HAVE_SQLITE3_DB_NAME",
            "HAVE_SQLITE3_ERROR_OFFSET",
        ]
        if ctx.attr.abi not in ["1.9.1", "2.0.0"]:
            defines.append("HAVE_RB_INTEGER_PACK")
        if ctx.attr.abi in ["3.1.0", "3.2.0", "3.3.0", "3.4.0", "4.0.0"]:
            defines.append("HAVE_RB_ENC_INTERNED_STR_CSTR")
    elif ctx.attr.abi not in ["1.9.1", "2.0.0", "2.1.0", "2.2.0"]:
        defines.append("__SKIP_GNU")
    toolchain, features, objects = _compile(ctx, defines, includes, [root] + ctx.files.sqlite_headers)
    if ctx.attr.sqlite:
        objects = objects + ctx.attr.sqlite[_RubyNativeObjectsInfo].files
    library = ctx.actions.declare_file(ctx.label.name + ".so")

    # Resolve libc and Ruby symbols in the pinned interpreter at load time.
    # Linking to the executor's newer libc would break historical runtimes.
    ctx.actions.run(
        executable = cc_common.get_tool_for_action(feature_configuration = features, action_name = ACTION_NAMES.c_compile),
        arguments = ["-fuse-ld=lld", "-shared", "-nostdlib", "-o", library.path] + [object.path for object in objects],
        inputs = depset(objects, transitive = [toolchain.all_files]),
        outputs = [library],
        mnemonic = "RubyNativeLink",
    )
    return [DefaultInfo(files = depset([library]))]

ruby_native_gem = rule(
    implementation = _native_impl,
    attrs = {
        "runtime": attr.label(mandatory = True),
        "abi": attr.string(mandatory = True),
        "srcs": attr.label_list(allow_files = True),
        "hdrs": attr.label_list(allow_files = True),
        "sqlite": attr.label(),
        "sqlite_headers": attr.label_list(allow_files = True),
    },
    toolchains = use_cc_toolchain(),
    fragments = ["cpp"],
)

def _app_impl(ctx):
    output = ctx.actions.declare_directory(ctx.label.name)
    runtime = ctx.attr.runtime[DefaultInfo].files.to_list()[0]
    manifest = ctx.actions.declare_file(ctx.label.name + ".inputs.json")
    ctx.actions.write(manifest, ctx.attr.manifest)
    args = ctx.actions.args()
    args.add(output.path)
    args.add(runtime.path)
    args.add(ctx.executable._launcher.path)
    args.add(manifest.path)
    args.add(ctx.file._build_script.path)
    args.add(ctx.file.bcrypt.path)
    args.add(ctx.file.sqlite.path)
    args.add_all(ctx.files.srcs)
    args.add("--gems")
    args.add_all(ctx.files.gems)
    ctx.actions.run(
        executable = ctx.executable._builder,
        arguments = [args],
        inputs = [runtime, manifest, ctx.file.bcrypt, ctx.file.sqlite, ctx.file._build_script] + ctx.files.srcs + ctx.files.gems,
        tools = [ctx.executable._builder, ctx.executable._launcher],
        outputs = [output],
        mnemonic = "RubyAppBundle",
        progress_message = "Building and checking RealWorld on Ruby %{label}",
    )
    return [DefaultInfo(files = depset([output]), runfiles = ctx.runfiles(files = [output]))]

ruby_app = rule(
    implementation = _app_impl,
    attrs = {
        "runtime": attr.label(mandatory = True),
        "manifest": attr.string(mandatory = True),
        "srcs": attr.label_list(allow_files = True),
        "gems": attr.label_list(allow_files = True),
        "bcrypt": attr.label(allow_single_file = True),
        "sqlite": attr.label(allow_single_file = True),
        "_builder": attr.label(default = Label("//tools:build_ruby_app"), executable = True, cfg = "exec"),
        "_launcher": attr.label(default = Label("//harness:app_launcher"), executable = True, cfg = "exec"),
        "_build_script": attr.label(default = Label("//fixtures/apps/ruby/realworld-sinatra:build.rb"), allow_single_file = True),
    },
)

def _responses_impl(ctx):
    output = ctx.actions.declare_file(ctx.label.name + ".json")
    app = ctx.attr.app[DefaultInfo].files.to_list()[0]
    runtime = ctx.attr.runtime[DefaultInfo].files.to_list()[0]
    args = ctx.actions.args()
    args.add("--output", output.path)
    args.add("--app", app.path)
    args.add("--runtime", runtime.path)
    args.add("--launcher", ctx.executable._launcher.path)
    args.add("--bootstrap", ctx.file._bootstrap.path)
    ctx.actions.run(
        executable = ctx.executable._recorder,
        arguments = [args],
        inputs = [app, runtime, ctx.file._bootstrap],
        tools = [ctx.executable._recorder, ctx.executable._launcher],
        outputs = [output],
        mnemonic = "RubyRealWorldResponses",
        progress_message = "Recording RealWorld responses on %{label}",
    )
    return [DefaultInfo(files = depset([output]))]

ruby_responses = rule(
    implementation = _responses_impl,
    attrs = {
        "app": attr.label(mandatory = True),
        "runtime": attr.label(mandatory = True),
        "_recorder": attr.label(default = Label("//tools:record_ruby_realworld"), executable = True, cfg = "exec"),
        "_launcher": attr.label(default = Label("//harness:app_launcher"), executable = True, cfg = "exec"),
        "_bootstrap": attr.label(default = Label("//fixtures/apps/ruby/realworld-sinatra:parity/server.rb"), allow_single_file = True),
    },
)
