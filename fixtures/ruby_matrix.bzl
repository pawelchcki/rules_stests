"""Declare every Ruby app from one matrix, with independently cached tests."""

load("@ruby_matrix_config//:versions.bzl", "RUBY_GEM_SETS", "RUBY_RUNTIMES")
load("@rules_python//python:defs.bzl", "py_test")
load("//corpus:registry.bzl", "REALWORLD_BASE_HURL_CASES")
load("//fixtures:ruby_build.bzl", "ruby_app", "ruby_native_gem", "ruby_responses", "ruby_runtime", "ruby_sqlite")
load("//rules:corpus_service.bzl", "corpus_service")
load("//rules:realworld_service_tests.bzl", "realworld_service_tests")

def _report_plan_impl(ctx):
    output = ctx.actions.declare_file(ctx.label.name + ".json")
    ctx.actions.write(output, ctx.attr.content)
    return [DefaultInfo(files = depset([output]))]

_report_plan = rule(implementation = _report_plan_impl, attrs = {"content": attr.string(mandatory = True)})

# A full RBE run peaked at 84 MB per test and typically used under half a CPU
# across service startup, HTTP requests and shutdown. Keep headroom while
# allowing the scheduler to pack these short processes onto the fleet.
_TEST_EXEC_PROPERTIES = {
    "test.EstimatedCPU": "0.5",
    "test.EstimatedMemory": "128MB",
}

def _gem_repo(gem):
    return "@ruby_gem_" + gem["name"].replace("-", "_") + "_" + gem["version"].replace(".", "_")

def ruby_app_matrix(name):
    """Declare the fixed Ruby version targets and an explicit aggregate suite.

    Args:
        name: Name of the aggregate test suite.
    """
    suite_name = name
    ruby_sqlite(name = "ruby_matrix_sqlite", srcs = ["@ruby_matrix_sqlite//:source", "//fixtures/apps/ruby/realworld-sinatra:sqlite_compat.c"], hdrs = ["@ruby_matrix_sqlite//:headers"])
    tests = []
    ci_tests = []
    receipts = []
    report_tests = {}
    for runtime in RUBY_RUNTIMES:
        suffix = runtime["series"].replace(".", "_")
        name = "ruby_" + suffix
        repository = "ruby_runtime_" + suffix + "_linux_amd64"
        ruby_runtime(
            name = name + "_runtime",
            image = "@{}//:{}".format(repository, repository),
        )
        gems = RUBY_GEM_SETS[runtime["gems"]]
        for gem in gems:
            if gem["name"] not in ["bcrypt", "sqlite3"]:
                continue
            options = {}
            if gem["name"] == "sqlite3":
                options = {"sqlite": ":ruby_matrix_sqlite", "sqlite_headers": ["@ruby_matrix_sqlite//:headers"]}
            ruby_native_gem(
                name = name + "_" + gem["name"],
                runtime = ":" + name + "_runtime",
                abi = runtime["abi"],
                srcs = [_gem_repo(gem) + "//:native_sources"],
                hdrs = [_gem_repo(gem) + "//:native_headers"],
                **options
            )
        ruby_app(
            name = name + "_rootfs",
            runtime = ":" + name + "_runtime",
            manifest = json.encode({"runtime": runtime, "gems": gems}),
            srcs = ["//fixtures/apps/ruby/realworld-sinatra:sources"],
            gems = [_gem_repo(gem) + "//:payload" for gem in gems],
            bcrypt = ":" + name + "_bcrypt",
            sqlite = ":" + name + "_sqlite3",
        )
        ruby_responses(
            name = name + "_responses",
            app = ":" + name + "_rootfs",
            runtime = ":" + name + "_runtime",
            tags = ["ruby-matrix", "manual"],
        )
        receipts.append(":" + name + "_responses")
        corpus_service(
            name = name + "_service",
            rootfs = ":" + name + "_rootfs",
            ruby_rootfs = ":" + name + "_runtime",
            runtime = "ruby",
            instance = name,
            command = "bin/server",
            args = ["--host", "127.0.0.1", "--port", "$${PORT}"],
            env = {"LANG": "C.UTF-8"},
            autoassign_port = True,
            so_reuseport_aware = False,
            http_health_check_address = "http://127.0.0.1:$${PORT}/api/tags",
            expected_start_duration = "3s",
            hygienic = False,
            shutdown_timeout = "10s",
        )
        realworld_service_tests(
            name = name,
            service = ":" + name + "_service",
            tags = ["ruby-matrix", "manual"],
            exec_properties = _TEST_EXEC_PROPERTIES,
        )
        version_tests = [":" + name + "_test", ":" + name + "_service_hygiene_test", ":" + name + "_hurl_test"]
        native.test_suite(name = name + "_suite", tests = version_tests, tags = ["ruby-matrix", "manual"])
        if runtime == RUBY_RUNTIMES[-1]:
            ci_tests = version_tests
        tests.extend(version_tests)
        report_tests[runtime["series"]] = ["//fixtures:" + name + "_test", "//fixtures:" + name + "_service_hygiene_test"] + [
            "//fixtures:" + name + "_hurl_test_" + case
            for case in REALWORLD_BASE_HURL_CASES
        ]
    _report_plan(
        name = "ruby_matrix_report_plan",
        content = json.encode({"runtimes": RUBY_RUNTIMES, "tests": report_tests, "parityTest": "//fixtures:ruby_matrix_parity_test"}),
    )
    py_test(
        name = "ruby_matrix_parity_test",
        srcs = ["//tools:ruby_realworld_parity.py"],
        main = "//tools:ruby_realworld_parity.py",
        args = ["--matrix", "$(rootpath //fixtures/apps/ruby/realworld-sinatra:matrix.json)"] + ["$(rootpath {})".format(receipt) for receipt in receipts],
        data = receipts + ["//fixtures/apps/ruby/realworld-sinatra:matrix.json"],
        tags = ["ruby-matrix", "manual"],
    )
    tests.append(":ruby_matrix_parity_test")
    native.test_suite(name = suite_name, tests = tests, tags = ["ruby-matrix", "manual"])
    # PRs exercise every API scenario on the newest pinned interpreter. Keep
    # response parity out of this suite: its data deps build every runtime.
    native.test_suite(name = "ruby_ci_suite", tests = ci_tests, tags = ["ruby-matrix", "manual"])
