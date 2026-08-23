"""Reusable RealWorld Hurl contract test for any rules_itest service."""

load("@rules_itest//:itest.bzl", "service_test")

def realworld_hurl_test(name, service, specs, **kwargs):
    """Runs a selected RealWorld Hurl suite against an assigned service port."""
    service_test(
        name = name,
        args = ["--service-suffix=" + service],
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
