"""Reusable RealWorld Hurl contract test for any rules_itest service."""

load("@rules_itest//:itest.bzl", "service_test")

def realworld_hurl_test(name, service, specs, jobs = 4, otel_sink = None, **kwargs):
    """Runs a selected RealWorld Hurl suite against an assigned service port."""
    args = [
        "--service-suffix=" + service,
        "--jobs=" + str(jobs),
    ]
    if otel_sink:
        args.append("--otel-sink-suffix=" + otel_sink)
    service_test(
        name = name,
        args = args,
        data = [
            "//bazel/itest:hurl_rootfs",
            specs,
        ],
        env = {
            "HURL_ROOTFS": "$(rootpath //bazel/itest:hurl_rootfs)",
            "HURL_SPECS": "$(rootpaths {})".format(specs),
        },
        services = [service],
        test = "//bazel/itest:realworld_hurl",
        **kwargs
    )
