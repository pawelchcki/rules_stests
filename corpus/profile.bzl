"""Atomic OpenTelemetry profile and generated standard-registry rules."""

OtelStandardRegistryInfo = provider(fields = ["scheme", "json"])

OtelProfileInfo = provider(fields = [
    "specification",
    "implementation_libraries",
    "normalized_proof_plan",
    "signals",
    "scenario_shapes",
    "manifest",
])

def _standard_registry_impl(ctx):
    scheme = ctx.actions.declare_file(ctx.label.name + ".scm")
    registry_json = ctx.actions.declare_file(ctx.label.name + ".json")
    ctx.actions.run(
        executable = ctx.executable._generator,
        inputs = [ctx.file.matrix, ctx.file.metadata],
        outputs = [scheme, registry_json],
        arguments = [
            "--matrix=" + ctx.file.matrix.path,
            "--metadata=" + ctx.file.metadata.path,
            "--scheme-out=" + scheme.path,
            "--json-out=" + registry_json.path,
        ],
        mnemonic = "OtelStandardRegistry",
        progress_message = "Generating language-neutral OpenTelemetry registry",
    )
    return [
        DefaultInfo(files = depset([scheme, registry_json])),
        OutputGroupInfo(scheme = depset([scheme]), registry = depset([registry_json])),
        OtelStandardRegistryInfo(scheme = scheme, json = registry_json),
    ]

otel_standard_registry = rule(
    implementation = _standard_registry_impl,
    attrs = {
        "matrix": attr.label(allow_single_file = True, mandatory = True),
        "metadata": attr.label(allow_single_file = True, mandatory = True),
        "_generator": attr.label(
            default = Label("//corpus:standard_registry_generator"),
            executable = True,
            cfg = "exec",
        ),
    },
)

def _profile_impl(ctx):
    registry = ctx.attr.standard_registry[OtelStandardRegistryInfo]
    plan = ctx.actions.declare_file(ctx.label.name + ".proof-plan.json")
    manifest = ctx.actions.declare_file(ctx.label.name + ".profile.json")
    shape_paths = {}
    shape_files = []
    for target, scenario in ctx.attr.scenario_shapes.items():
        files = target.files.to_list()
        if len(files) != 1:
            fail("scenario shape %s must provide exactly one file" % target.label)
        shape_paths[scenario] = files[0].short_path
        shape_files.append(files[0])
    common = [
        registry.scheme,
        ctx.file.validation_library,
        ctx.file.trace_shape_library,
        ctx.file.capture_shapes_library,
    ] + ctx.files.proof_rule_tables + [
        ctx.file.proof_library,
        ctx.file.contract_library,
        ctx.file.profile_library,
    ] + ctx.files.runtime_libraries + ctx.files.implementation_libraries + [ctx.file.specification]
    arguments = ctx.actions.args()
    arguments.add("--profile=" + ctx.file.specification.path)
    arguments.add("--registry=" + registry.json.path)
    for source in ctx.files.proof_rule_tables:
        arguments.add("--proof-rules=" + source.path)
    arguments.add("--capture-shapes=" + ctx.file.capture_shapes_library.path)
    arguments.add("--out=" + plan.path)
    arguments.add("--manifest-out=" + manifest.path)
    arguments.add("--profile-id=" + ctx.attr.profile_id)
    arguments.add("--program=" + ctx.file.program.path)
    for source in ctx.files.implementation_libraries:
        arguments.add("--implementation=" + source.path)
    for source in common:
        arguments.add("--library=" + source.path)
    for name in ["otel.profile", "realworld.profile.%s" % ctx.attr.profile_id]:
        arguments.add("--import=" + name)
    for signal in ctx.attr.signals:
        arguments.add("--signal=" + signal)
    for scenario in ctx.attr.scenarios:
        arguments.add("--scenario=" + scenario)
    for target, scenario in ctx.attr.scenario_shapes.items():
        arguments.add("--shape=%s,%s" % (scenario, target.files.to_list()[0].path))
    ctx.actions.run(
        executable = ctx.executable._compiler,
        inputs = depset([ctx.file.specification, registry.json, ctx.file.program] + common + shape_files),
        outputs = [plan, manifest],
        arguments = [arguments],
        mnemonic = "OtelProfilePlan",
        progress_message = "Compiling normalized proof plan for %s" % ctx.attr.profile_id,
    )

    return [
        DefaultInfo(files = depset([manifest])),
        OutputGroupInfo(
            manifest = depset([manifest]),
            proof_plan = depset([plan]),
        ),
        OtelProfileInfo(
            specification = ctx.file.specification,
            implementation_libraries = depset(ctx.files.implementation_libraries),
            normalized_proof_plan = plan,
            signals = tuple(ctx.attr.signals),
            scenario_shapes = shape_paths,
            manifest = manifest,
        ),
    ]

otel_profile = rule(
    implementation = _profile_impl,
    attrs = {
        "profile_id": attr.string(mandatory = True),
        "specification": attr.label(allow_single_file = [".scm"], mandatory = True),
        "implementation_libraries": attr.label_list(allow_files = [".scm"], mandatory = True),
        "runtime_libraries": attr.label_list(allow_files = [".scm"], mandatory = True),
        "signals": attr.string_list(mandatory = True),
        "scenarios": attr.string_list(mandatory = True),
        "scenario_shapes": attr.label_keyed_string_dict(allow_files = [".scm"]),
        "standard_registry": attr.label(providers = [OtelStandardRegistryInfo], mandatory = True),
        "proof_rule_tables": attr.label_list(
            allow_files = [".scm"],
            default = [
                Label("//corpus:otel/proofs/traces.scm"),
                Label("//corpus:otel/proofs/metrics.scm"),
                Label("//corpus:otel/proofs/logs.scm"),
                Label("//corpus:otel/proofs/resource.scm"),
                Label("//corpus:otel/proofs/exporters.scm"),
            ],
        ),
        "proof_library": attr.label(allow_single_file = [".scm"], default = Label("//corpus:otel/proofs.scm")),
        "validation_library": attr.label(allow_single_file = [".scm"], default = Label("//corpus:otel/validation.scm")),
        "trace_shape_library": attr.label(allow_single_file = [".scm"], default = Label("//corpus:otel/trace_shape.scm")),
        "capture_shapes_library": attr.label(allow_single_file = [".scm"], default = Label("//corpus:otel/capture/shapes.scm")),
        "profile_library": attr.label(allow_single_file = [".scm"], default = Label("//corpus:otel/profile.scm")),
        "contract_library": attr.label(allow_single_file = [".scm"], default = Label("//corpus:realworld/contract.scm")),
        "program": attr.label(allow_single_file = [".scm"], default = Label("//corpus:realworld/programs/validate_profile.scm")),
        "_compiler": attr.label(
            default = Label("//corpus:profile_plan_compiler"),
            executable = True,
            cfg = "exec",
        ),
    },
)
