"""Atomic OpenTelemetry profile and generated standard-registry rules."""

load("//corpus:registry.bzl", "REALWORLD_HURL_CASES")

_RULESET_REPOSITORY = Label("//:MODULE.bazel").repo_name

OtelStandardRegistryInfo = provider(fields = ["scheme", "json", "matrix", "metadata"])

OtelProfileInfo = provider(fields = [
    "profile_id",
    "repository",
    "spec_path",
    "specification",
    "implementation_libraries",
    "normalized_proof_plan",
    "signals",
    "scenarios",
    "scenario_shapes",
    "scenario_shape_sources",
    "registry_matrix",
    "registry_metadata",
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
        OtelStandardRegistryInfo(
            scheme = scheme,
            json = registry_json,
            matrix = ctx.file.matrix,
            metadata = ctx.file.metadata,
        ),
    ]

otel_standard_registry = rule(
    implementation = _standard_registry_impl,
    attrs = {
        "matrix": attr.label(allow_single_file = True, mandatory = True),
        "metadata": attr.label(allow_single_file = True, mandatory = True),
        "_generator": attr.label(
            default = Label("//report:registry_generator"),
            executable = True,
            cfg = "exec",
        ),
    },
)

def _profile_impl(ctx):
    registry = ctx.attr.standard_registry[OtelStandardRegistryInfo]
    profile_repository = ctx.label.repo_name
    if ctx.file.specification.owner.repo_name != profile_repository:
        fail("profile specification {} must be owned by the same repository as {}".format(
            ctx.file.specification.owner,
            ctx.label,
        ))
    plan = ctx.actions.declare_file(ctx.label.name + ".proof-plan.json")
    manifest = ctx.actions.declare_file(ctx.label.name + ".profile.json")
    shape_paths = {}
    shape_sources = {}
    shape_files = []
    for target, scenario in ctx.attr.scenario_shapes.items():
        files = target.files.to_list()
        if len(files) != 1:
            fail("scenario shape %s must provide exactly one file" % target.label)
        if files[0].owner.repo_name != profile_repository:
            fail("scenario shape {} for {} must be owned by the same repository as {}".format(
                files[0].owner,
                scenario,
                ctx.label,
            ))
        shape_paths[scenario] = files[0].path
        shape_sources[scenario] = files[0].short_path
        shape_files.append(files[0])
    core_libraries = ctx.attr.core_libraries.files.to_list()
    common = [registry.scheme] + core_libraries + ctx.files.runtime_libraries + ctx.files.implementation_libraries + [ctx.file.specification]

    capture_shapes = None
    proof_rule_tables = []
    for source in core_libraries:
        if source.short_path.endswith("otel/capture/shapes.scm"):
            capture_shapes = source
        elif "/otel/proofs/" in source.short_path:
            proof_rule_tables.append(source)
    if not capture_shapes:
        fail("core_libraries must contain otel/capture/shapes.scm")
    arguments = ctx.actions.args()
    arguments.add("--profile=" + ctx.file.specification.path)
    arguments.add("--registry=" + registry.json.path)
    for source in proof_rule_tables:
        arguments.add("--proof-rules=" + source.path)
    arguments.add("--capture-shapes=" + capture_shapes.path)
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
            profile_id = ctx.attr.profile_id,
            repository = ctx.label.repo_name,
            spec_path = ctx.file.specification.short_path,
            specification = ctx.file.specification,
            implementation_libraries = depset(ctx.files.implementation_libraries),
            normalized_proof_plan = plan,
            signals = tuple(ctx.attr.signals),
            scenarios = tuple(ctx.attr.scenarios),
            scenario_shapes = shape_paths,
            scenario_shape_sources = shape_sources,
            registry_matrix = registry.matrix,
            registry_metadata = registry.metadata,
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
        "core_libraries": attr.label(
            allow_files = [".scm"],
            default = Label("//corpus:core_libraries"),
        ),
        "program": attr.label(allow_single_file = [".scm"], default = Label("//corpus:realworld/programs/validate_profile.scm")),
        "_compiler": attr.label(
            default = Label("//report:plan_compiler"),
            executable = True,
            cfg = "exec",
        ),
    },
)

def _validate_scheme_identifier(value, field):
    if not value:
        fail("{} must be a non-empty Scheme identifier".format(field))
    first = value[0]
    if not ((first >= "a" and first <= "z") or
            (first >= "A" and first <= "Z") or
            first == "_"):
        fail("{} {} is not a valid Scheme identifier".format(field, value))
    for index in range(1, len(value)):
        character = value[index]
        if not ((character >= "a" and character <= "z") or
                (character >= "A" and character <= "Z") or
                (character >= "0" and character <= "9") or
                character in "-+_"):
            fail("{} {} is not a valid Scheme identifier".format(field, value))

def otel_realworld_profile(
        name,
        specification,
        runtime_libraries,
        implementation_libraries,
        signals,
        profile_id = None,
        scenario_shapes = {},
        shape_root = None,
        scenarios = REALWORLD_HURL_CASES,
        standard_registry = Label("//corpus:otel_standard_registry"),
        core_libraries = Label("//corpus:core_libraries"),
        program = Label("//corpus:realworld/programs/validate_profile.scm"),
        **kwargs):
    """Declares a RealWorld profile and its normalized proof-plan filegroup."""
    if shape_root and scenario_shapes:
        fail("shape_root and scenario_shapes are mutually exclusive")
    if not scenarios:
        fail("scenarios must contain at least one RealWorld scenario")
    unknown_scenarios = [scenario for scenario in scenarios if scenario not in REALWORLD_HURL_CASES]
    if unknown_scenarios:
        fail("scenarios contains unknown RealWorld scenarios: {}".format(", ".join(sorted(unknown_scenarios))))
    if len({scenario: True for scenario in scenarios}) != len(scenarios):
        fail("scenarios contains duplicate RealWorld scenarios")
    if not signals:
        fail("signals must contain at least traces")
    unknown_signals = [signal for signal in signals if signal not in ["traces", "metrics", "logs"]]
    if unknown_signals:
        fail("signals contains unknown OTLP signals: {}".format(", ".join(sorted(unknown_signals))))
    if len({signal: True for signal in signals}) != len(signals):
        fail("signals contains duplicate OTLP signals")
    if "traces" not in signals:
        fail("signals must include traces")
    unknown = [scenario for scenario in scenario_shapes if scenario not in scenarios]
    if unknown:
        fail("scenario_shapes contains unknown scenarios: {}".format(", ".join(sorted(unknown))))
    resolved_profile_id = profile_id or name
    _validate_scheme_identifier(resolved_profile_id, "profile_id")
    shapes = dict(scenario_shapes)
    if shape_root:
        shapes = {
            scenario: "{}/{}.scm".format(shape_root.rstrip("/"), scenario)
            for scenario in scenarios
        }
    shapes_by_label = {}
    for scenario, label in shapes.items():
        if label in shapes_by_label:
            fail("scenario_shapes reuses shape label {} for scenarios {} and {}".format(
                label,
                shapes_by_label[label],
                scenario,
            ))
        shapes_by_label[label] = scenario
    otel_profile(
        name = name,
        profile_id = resolved_profile_id,
        specification = specification,
        runtime_libraries = runtime_libraries,
        implementation_libraries = implementation_libraries,
        signals = signals,
        scenarios = scenarios,
        scenario_shapes = shapes_by_label,
        standard_registry = standard_registry,
        core_libraries = core_libraries,
        program = program,
        **kwargs
    )
    native.filegroup(
        name = name + ".proof_plan",
        srcs = [":" + name],
        output_group = "proof_plan",
    )

def _report_manifest_impl(ctx):
    output = ctx.actions.declare_file(ctx.label.name + ".json")
    entries = []
    plans = []
    registry_matrix = None
    registry_metadata = None
    profile_labels = {target.label: True for target in ctx.attr.profiles}
    for target in ctx.attr.unavailable_profiles:
        if target.label not in profile_labels:
            fail("unavailable report profile {} is not in profiles".format(target.label))
    unavailable = {target.label: True for target in ctx.attr.unavailable_profiles}
    for target in ctx.attr.profiles:
        profile = target[OtelProfileInfo]
        if registry_matrix == None:
            registry_matrix = profile.registry_matrix
            registry_metadata = profile.registry_metadata
        elif (profile.registry_matrix.path != registry_matrix.path or
              profile.registry_metadata.path != registry_metadata.path):
            fail("report profiles must use one standard_registry; {} uses a different registry".format(target.label))
        plans.append(profile.normalized_proof_plan)
        entries.append({
            "id": profile.profile_id,
            "repository": "rules_stests" if _RULESET_REPOSITORY and profile.repository == _RULESET_REPOSITORY else profile.repository,
            "spec": _repository_relative(profile.spec_path),
            "plan": profile.normalized_proof_plan.path,
            "scenarios": list(profile.scenarios),
            "shapes": profile.scenario_shapes,
            "shapeSources": {
                scenario: _repository_relative(path)
                for scenario, path in profile.scenario_shape_sources.items()
            },
            "unavailable": target.label in unavailable,
        })
    if registry_matrix == None:
        fail("profiles must contain at least one OpenTelemetry profile")
    ctx.actions.write(output, json.encode(entries) + "\n")
    return [
        DefaultInfo(files = depset([output] + plans + [registry_matrix, registry_metadata])),
        OutputGroupInfo(
            report_manifest = depset([output]),
            report_matrix = depset([registry_matrix]),
            report_metadata = depset([registry_metadata]),
        ),
    ]

otel_report_manifest = rule(
    implementation = _report_manifest_impl,
    attrs = {
        "profiles": attr.label_list(providers = [OtelProfileInfo]),
        "unavailable_profiles": attr.label_list(providers = [OtelProfileInfo]),
    },
)

def _repository_relative(path):
    if path.startswith("../"):
        parts = path.split("/")
        return "/".join(parts[2:])
    return path
