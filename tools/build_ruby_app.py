"""Assemble a small app bundle and verify it using its separate pinned Ruby."""

import json
from pathlib import Path
import shutil
import subprocess
import sys


def main(arguments):
    output, runtime, launcher, manifest_path, build_script, bcrypt, sqlite, *files = arguments
    output = Path(output).resolve()
    runtime = Path(runtime).resolve()
    manifest = json.loads(Path(manifest_path).read_text())
    abi = manifest["runtime"]["abi"]
    app = output / "opt/app"
    source = app / "src"
    marker = files.index("--gems")
    for filename in files[:marker]:
        path = Path(filename)
        relative = path.as_posix().split("realworld-sinatra/", 1)[1]
        target = source / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(path, target)
    gems = {gem["name"] + "-" + gem["version"]: gem for gem in manifest["gems"]}
    archives = []
    gem_root = app / "bundle/ruby" / abi
    for filename in files[marker + 1:]:
        path = Path(filename)
        repository = path.parts[1]
        gem = next(g for g in gems.values() if repository.endswith("ruby_gem_" + g["name"].replace("-", "_") + "_" + g["version"].replace(".", "_")))
        name = gem["name"] + "-" + gem["version"]
        if path.name == "source.gem":
            archives.extend([name, str(path.resolve())])
            continue
        relative = path.as_posix().split("/data/", 1)[1]
        target = gem_root / "gems" / name / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(path, target)
    for name, gem in gems.items():
        if gem["name"] in ("bcrypt", "sqlite3"):
            native = Path(bcrypt if gem["name"] == "bcrypt" else sqlite)
            relative = "bcrypt_ext.so" if gem["name"] == "bcrypt" else "sqlite3/sqlite3_native.so"
            target = gem_root / "gems" / name / "lib" / relative
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(native, target)
    (app / "build-inputs.json").write_text(json.dumps(manifest, sort_keys=True) + "\n")
    environment = {"APP_STATE_DIR": str(app / "seed"), "LANG": "C.UTF-8"}
    # Do not inherit host GEM_PATH, Ruby options, loaders or application state.
    subprocess.run([
        str(Path(launcher).resolve()), "--runtime=ruby", "--rootfs=" + str(output),
        "--ruby-rootfs=" + str(runtime), "--instance=build", "--", str(Path(build_script).resolve()),
        str(app), *archives,
    ], env=environment, check=True)
    # Contract tests populated the build database; package a pristine schema.
    (app / "seed/contract.sqlite3").unlink(missing_ok=True)


if __name__ == "__main__":
    main(sys.argv[1:])
