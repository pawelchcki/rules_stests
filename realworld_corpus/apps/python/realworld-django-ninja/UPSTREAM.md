# Upstream provenance

- Repository: <https://github.com/c4ffein/realworld-django-ninja>
- Commit: `04ef47ced437ee8795a13bdcbc2eff2be19e33bd`
- Imported: 2026-08-23
- License: MIT (`LICENSE`)

Corpus-specific changes are limited to the Docker/Compose setup and omission of
the upstream frontend and RealWorld-spec Git submodules. The image byte-compiles
the backend Python sources during its build and runs against SQLite by default.
