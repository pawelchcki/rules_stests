# Portable bundle

The static launcher locates the Python runtime relative to itself and executes
`entrypoint.py`. The OCI build creates `seed/realworld.sqlite3` directly from
the current SQLAlchemy metadata. Runtime startup only reflinks or copies that
ready seed into the writable state directory; it never runs migrations.
