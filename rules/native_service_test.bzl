"""Consumer workloads sharing the native intake and schema-v2 receipt path."""

load("@rules_itest//:itest.bzl", "service_test")

_DRIVER = Label("//harness:realworld_hurl")
_HURL_ROOTFS = Label("//harness:hurl_rootfs")

def _profile_data_impl(ctx):
    return [DefaultInfo(files = ctx.attr.profile[DefaultInfo].default_runfiles.files)]

_profile_data = rule(
    implementation = _profile_data_impl,
    attrs = {"profile": attr.label(mandatory = True)},
)

def native_service_test(name, service, telemetry_profile, telemetry_sink, scenario, client = None, client_data = [], tags = [], **kwargs):
    args = [
        "--service-suffix=" + str(native.package_relative_label(service)),
        "--telemetry-sink-suffix=" + str(native.package_relative_label(telemetry_sink)),
        "--telemetry-profile-manifest=$(rlocationpath {})".format(telemetry_profile),
        "--telemetry-case=" + scenario,
        "--native-scenario=" + scenario,
        "--hurl-rootfs=$(rlocationpath {})".format(_HURL_ROOTFS),
    ]
    data = [telemetry_profile, _HURL_ROOTFS] + client_data
    _profile_data(name = name + "_profile_data", profile = telemetry_profile)
    data.append(":" + name + "_profile_data")
    if client:
        args.append("--native-client=$(rlocationpath {})".format(client))
        data.append(client)
    service_test(
        name = name,
        services = [service],
        test = _DRIVER,
        args = args,
        data = data,
        tags = tags + ["telemetry"],
        **kwargs
    )
