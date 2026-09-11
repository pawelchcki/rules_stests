"""Consumer-side checks for public telemetry providers and injection helpers."""

load(
    "@rules_stests//rules:defs.bzl",
    "TelemetryProfileInfo",
    "datadog_env",
    "datadog_python_injection",
    "instrumentation_injection",
)

def _telemetry_api_check_impl(ctx):
    entries = []
    files = []
    for target, expected_family, expected_wire in [
        (ctx.attr.datadog_profile, "datadog", "v0.5"),
        (ctx.attr.otel_profile, "otlp", ""),
    ]:
        profile = target[TelemetryProfileInfo]
        if profile.family != expected_family or profile.wire_version != expected_wire:
            fail("public TelemetryProfileInfo lost protocol identity for {}".format(target.label))
        if profile.repository != ctx.label.repo_name:
            fail("consumer-owned profile was attributed to the ruleset repository")
        if profile.specification.owner.repo_name != ctx.label.repo_name:
            fail("consumer specification does not retain its repository identity")
        if expected_family == "datadog" and (not profile.reference_profile or len(profile.scenarios) != 16):
            fail("consumer Datadog profile did not inherit its complete external reference")
        files.extend([profile.manifest, profile.normalized_proof_plan])
        entries.append({
            "family": profile.family,
            "wireVersion": profile.wire_version,
            "profileId": profile.profile_id,
            "repository": profile.repository,
            "scenarios": profile.scenarios,
        })
    result = ctx.actions.declare_file(ctx.label.name + ".json")
    ctx.actions.write(result, json.encode(entries) + "\n")
    # Building this target also compiles both consumer-owned profile manifests
    # and proof plans, checking cross-repository Scheme library resolution.
    return [DefaultInfo(files = depset([result] + files))]

_telemetry_api_check = rule(
    implementation = _telemetry_api_check_impl,
    attrs = {
        "datadog_profile": attr.label(mandatory = True, providers = [TelemetryProfileInfo]),
        "otel_profile": attr.label(mandatory = True, providers = [TelemetryProfileInfo]),
    },
)

def telemetry_api_check(name, datadog_profile, otel_profile):
    """Checks public default labels and compiles both consumer profile families."""
    rootfs = Label("@rules_stests//harness:datadog_python_rootfs")
    standard = datadog_python_injection(aiohttp = True)
    if standard.rootfs != rootfs:
        fail("Datadog helper default rootfs resolved in the consumer repository")
    neutral = instrumentation_injection(
        rootfs = rootfs,
        prepend_path = {"PYTHONPATH": "{instrumentation_rootfs}"},
        require = ["{instrumentation_rootfs}/sitecustomize.py"],
    )
    if not neutral.flags[0].startswith("--instrumentation-rootfs="):
        fail("neutral injection does not use the public launcher option")
    sink = Label("@rules_stests//harness:telemetry_sink_service")
    env = datadog_env(service = "example-datadog")
    if env["DD_TRACE_AGENT_URL"] != "http://127.0.0.1:$${%s}" % str(sink):
        fail("Datadog exporter default sink resolved in the consumer repository")
    if [key for key in env if key.startswith("OTEL_")]:
        fail("Datadog injection introduced OTel defaults")
    _telemetry_api_check(
        name = name,
        datadog_profile = datadog_profile,
        otel_profile = otel_profile,
    )
