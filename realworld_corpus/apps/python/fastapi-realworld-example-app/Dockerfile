# syntax=docker/dockerfile:1.7
ARG SOURCE_DATE_EPOCH=0
FROM golang:1.25-alpine@sha256:1ae0735f00daffa3aaf1363a5184c0d2dc55c78e3db4ec70241cdac97bf84b59 AS launcher
WORKDIR /src
COPY bundle/launcher.go ./launcher.go
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
    go build -trimpath -ldflags="-s -w -buildid=" -o /out/app ./launcher.go

FROM ghcr.io/astral-sh/uv:0.12.5-debian-slim@sha256:53476714c941e4fe1ec3d7c24c405681752365d882d165a848bc22d84f19106a AS builder
ENV UV_CACHE_DIR=/tmp/uv-cache \
    UV_LINK_MODE=copy \
    UV_PYTHON_INSTALL_DIR=/opt/uv-python \
    UV_PYTHON=3.9.25
WORKDIR /build

COPY pyproject.toml uv.lock ./
RUN uv python install 3.9.25 \
    && uv export --frozen --no-dev --no-emit-project --format requirements-txt --output-file /tmp/requirements.txt \
    && python_path="$(uv python find 3.9.25)" \
    && python_root="$(dirname "$(dirname "$python_path")")" \
    && mkdir -p /rootfs/opt/app \
    && cp -a "$python_root" /rootfs/opt/app/python \
    && uv pip install --python "$python_path" --target /rootfs/opt/app/site-packages \
        --require-hashes --no-deps --requirements /tmp/requirements.txt

COPY app /rootfs/opt/app/src/app
COPY alembic.ini /rootfs/opt/app/src/alembic.ini
COPY bundle/entrypoint.py /rootfs/opt/app/entrypoint.py
COPY LICENSE /rootfs/opt/app/licenses/application-LICENSE
COPY --from=launcher /out/app /rootfs/opt/app/bin/app

RUN mkdir -p /rootfs/data /rootfs/lib /rootfs/lib64 /rootfs/etc/ssl/certs /rootfs/usr/share/doc/libc6 \
    && cp -a /lib/x86_64-linux-gnu /rootfs/lib/ \
    && cp -L /lib64/ld-linux-x86-64.so.2 /rootfs/lib64/ld-linux-x86-64.so.2 \
    && if [ -f /etc/ssl/certs/ca-certificates.crt ]; then cp -L /etc/ssl/certs/ca-certificates.crt /rootfs/etc/ssl/certs/ca-certificates.crt; fi \
    && if [ -f /usr/share/doc/libc6/copyright ]; then cp -a /usr/share/doc/libc6/copyright /rootfs/usr/share/doc/libc6/copyright; fi \
    && /rootfs/opt/app/python/bin/python3 -m compileall \
        --invalidation-mode checked-hash -q -f /rootfs/opt/app/src /rootfs/opt/app/entrypoint.py \
    && chown -R 65532:65532 /rootfs/data

FROM scratch
COPY --from=builder /rootfs/ /
ENV APP_ENV=dev \
    APP_STATE_DIR=/data \
    PYTHONUNBUFFERED=1 \
    SECRET_KEY=rules-stests-development-only-secret
USER 65532:65532
WORKDIR /opt/app/src
EXPOSE 8000
ENTRYPOINT ["/opt/app/bin/app"]
CMD ["run", "--host", "0.0.0.0", "--port", "8000"]
