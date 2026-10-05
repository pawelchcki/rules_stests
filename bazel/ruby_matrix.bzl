"""Pinned Ruby runtimes and source gems for the Bazel application matrix."""

load("@rules_oci//oci:pull.bzl", "oci_pull")

_MATRIX = Label("//fixtures/apps/ruby/realworld-sinatra:matrix.json")
_LOCK = Label("//fixtures/apps/ruby/realworld-sinatra:dependencies.lock.json")
_OTEL_LOCK = Label("//fixtures/apps/ruby/realworld-sinatra:telemetry.lock.json")

def _config_impl(ctx):
    ctx.file("versions.bzl", "RUBY_RUNTIMES = " + repr(json.decode(ctx.read(ctx.attr.matrix))["runtimes"]) + "\nRUBY_GEM_SETS = " + repr(json.decode(ctx.read(ctx.attr.lock))["gemSets"]) + "\nRUBY_TELEMETRY = " + repr(json.decode(ctx.read(ctx.attr.otel_lock))) + "\n")
    ctx.file("BUILD.bazel", 'exports_files(["versions.bzl"])\n')

_config = repository_rule(
    implementation = _config_impl,
    attrs = {"matrix": attr.label(allow_single_file = True), "lock": attr.label(allow_single_file = True), "otel_lock": attr.label(allow_single_file = True)},
)

def _gem_impl(ctx):
    ctx.download(url = "https://rubygems.org/downloads/{}-{}.gem".format(ctx.attr.gem, ctx.attr.version), sha256 = ctx.attr.sha256, output = "source.tar")
    ctx.extract("source.tar", output = "package")
    ctx.symlink("source.tar", "source.gem")
    ctx.extract("package/data.tar.gz", output = "data")
    if ctx.attr.gem == "bcrypt" and ctx.attr.version != "3.1.11":
        native = 'glob(["data/ext/mri/*.c", "data/ext/mri/*.S"], exclude = ["data/ext/mri/crypt.c"], allow_empty = True)'
    elif ctx.attr.gem == "bcrypt":
        native = 'glob(["data/ext/mri/*.c", "data/ext/mri/*.S"], allow_empty = True)'
    elif ctx.attr.gem == "google-protobuf":
        native = 'glob(["data/ext/google/protobuf_c/*.c", "data/ext/google/protobuf_c/third_party/utf8_range/*.c"], exclude = ["data/ext/google/protobuf_c/wrap_memcpy.c"], allow_empty = True)'
    else:
        native = 'glob(["data/ext/sqlite3/*.c"], allow_empty = True)'
    ctx.file("BUILD.bazel", """package(default_visibility = ["//visibility:public"])
filegroup(name = "payload", srcs = glob(["data/lib/**", "data/cdata/**", "data/LICENSE*", "data/COPYING*", "data/MIT-LICENSE*", "data/README*"], allow_empty = True) + ["source.gem"])
filegroup(name = "native_sources", srcs = %s)
filegroup(name = "native_headers", srcs = glob(["data/ext/**/*.h"], allow_empty = True))
""" % native)

_gem = repository_rule(implementation = _gem_impl, attrs = {"gem": attr.string(), "version": attr.string(), "sha256": attr.string()})

def _legacy_impl(ctx):
    # rules_oci rejects historical schema-1 images. These schema-2 descriptors
    # retain the original ordered layers, verified by the Bazel downloader.
    source = ctx.read(ctx.attr.manifest)
    manifest = json.decode(source)
    registry = "https://registry-1.docker.io/v2/library/ruby/blobs/"
    ctx.download("https://auth.docker.io/token?service=registry.docker.io&scope=repository:library/ruby:pull", output = "token.json")
    token = json.decode(ctx.read("token.json"))["token"]
    ctx.delete("token.json")
    pending = []
    for digest in {layer["digest"]: True for layer in manifest["layers"]}:
        url = registry + digest
        pending.append(ctx.download(url = url, sha256 = digest[len("sha256:"):], output = "blobs/" + digest.replace(":", "/"), auth = {url: {"type": "pattern", "pattern": "Bearer <password>", "password": token}}, block = False))
    for download in pending:
        download.wait()
    ctx.file("blobs/sha256/" + ctx.attr.manifest_sha256, source)
    ctx.file("blobs/sha256/44136fa355b3678a1146ad16f7e8649e94fb4fc21fe77e8310c060f61caaff8a", "{}")
    ctx.file("index.json", json.encode({"schemaVersion": 2, "manifests": [{"mediaType": "application/vnd.oci.image.manifest.v1+json", "digest": "sha256:" + ctx.attr.manifest_sha256, "size": len(source)}]}))
    ctx.file("oci-layout", '{"imageLayoutVersion":"1.0.0"}')
    ctx.file("BUILD.bazel", """load("@aspect_bazel_lib//lib:copy_to_directory.bzl", "copy_to_directory")
copy_to_directory(name = %r, srcs = glob(["blobs/**", "index.json", "oci-layout"]), out = "layout", visibility = ["//visibility:public"])
""" % ctx.attr.target)

_legacy = repository_rule(implementation = _legacy_impl, attrs = {"manifest": attr.label(allow_single_file = True), "manifest_sha256": attr.string(), "target": attr.string()})

def _matrix_impl(ctx):
    runtimes = json.decode(ctx.read(_MATRIX))["runtimes"]
    gem_sets = json.decode(ctx.read(_LOCK))["gemSets"]
    gem_sets.update(json.decode(ctx.read(_OTEL_LOCK))["gemSets"])
    _config(name = "ruby_matrix_config", matrix = _MATRIX, lock = _LOCK, otel_lock = _OTEL_LOCK)
    repositories = ["ruby_matrix_config"]
    for runtime in runtimes:
        name = "ruby_runtime_" + runtime["series"].replace(".", "_")
        if runtime["schema"] == 1:
            _legacy(name = name + "_linux_amd64", target = name + "_linux_amd64", manifest = Label("//bazel:ruby_legacy/{}.json".format(runtime["version"])), manifest_sha256 = "ecf0a463ac32a833e540122344a573681e434897218e420093c1987b6a4edf44" if runtime["series"] == "1.9.3" else "cbf0903f41017efa794497d3fb2192df206dd90eb1788e259af4d53d257ce5ab")
        else:
            oci_pull(name = name, image = "docker.io/library/ruby", digest = runtime["image"].split("@")[1], platforms = ["linux/amd64"], is_bzlmod = True)
        repositories.append(name + "_linux_amd64")
    gems = {gem["name"] + "_" + gem["version"]: gem for gems in gem_sets.values() for gem in gems}
    for key, gem in gems.items():
        name = "ruby_gem_" + key.replace("-", "_").replace(".", "_")
        _gem(name = name, gem = gem["name"], version = gem["version"], sha256 = gem["sha256"])
        repositories.append(name)
    return ctx.extension_metadata(root_module_direct_deps = repositories, root_module_direct_dev_deps = [], reproducible = True)

ruby_matrix = module_extension(implementation = _matrix_impl)
