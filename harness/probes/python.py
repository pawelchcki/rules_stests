# Shared fixture probes. This code is embedded by the launcher, and has no
# effect unless the fixture explicitly opts in. No application files change.
if os.environ.get("RULES_STESTS_PROBES") == "true" or os.environ.get("RULES_STESTS_SQL_MARKERS") == "true":
    import contextvars
    import secrets
    import threading
    import time
    import urllib.parse
    from contextlib import contextmanager
    from ddtrace import tracer

    _request_marker = contextvars.ContextVar("rules_stests_sql_marker", default=None)
    _held = {}
    _held_lock = threading.Lock()

    def _mark_sql(statement):
        marker = _request_marker.get()
        if marker and isinstance(statement, str) and "/* rules_stests_request=" not in statement:
            marker[2] += 1
            return statement + " /* rules_stests_request=" + marker[0] + "; marker=" + marker[1] + " */"
        return statement

    def _marker(request_id):
        if not request_id or len(request_id) > 80 or not all(c in "0123456789abcdef-" for c in request_id):
            raise ValueError("invalid rules_stests request identifier")
        return [request_id, secrets.token_hex(16), 0]

    def _probe_spans(kind):
        with tracer.trace("probe.parent", resource=kind) as parent:
            if kind == "keep": parent.context.sampling_priority = 2
            if kind == "drop": parent.context.sampling_priority = -1
            for index in range(3):
                with tracer.trace("probe.child", resource=str(index)) as child:
                    child.set_tag("probe.index", str(index))

    def _target_url(value):
        parsed = urllib.parse.urlsplit(value)
        if parsed.scheme != "http" or parsed.hostname not in ("127.0.0.1", "localhost"):
            raise ValueError("probe target must be loopback HTTP")
        return value

    if os.environ.get("RULES_STESTS_DATADOG_AIOHTTP_ENABLED") == "true":
        from aiohttp import web, ClientSession
        from sqlalchemy import event
        from sqlalchemy.engine import Engine

        @event.listens_for(Engine, "before_cursor_execute", retval=True)
        def _marked_cursor_execute(conn, cursor, statement, parameters, context, executemany):
            return _mark_sql(statement), parameters

        @web.middleware
        async def _aio_marker(request, handler):
            request_id = request.headers.get("X-Rules-Stests-Request-Id")
            if not request_id or os.environ.get("RULES_STESTS_SQL_MARKERS") != "true":
                return await handler(request)
            marker = _marker(request_id)
            token = _request_marker.set(marker)
            try:
                response = await handler(request)
                response.headers["X-Rules-Stests-Sql-Marker"] = marker[1]
                response.headers["X-Rules-Stests-Sql-Count"] = str(marker[2])
                return response
            finally:
                _request_marker.reset(token)

        async def _aio_probe(request):
            kind = request.match_info["kind"]
            if kind == "exception":
                with tracer.trace("probe.exception"):
                    raise RuntimeError("controlled rules_stests exception")
            if kind in ("nested", "keep", "drop", "partial"):
                _probe_spans(kind)
                if kind == "partial":
                    key = request.query["key"]
                    event = asyncio.Event()
                    with _held_lock: _held[key] = event
                    try: await asyncio.wait_for(event.wait(), timeout=15)
                    finally:
                        with _held_lock: _held.pop(key, None)
                return web.json_response({"children": 3})
            if kind == "state":
                with _held_lock: held = request.query["key"] in _held
                return web.json_response({"held": held})
            if kind == "release":
                with _held_lock: event = _held.get(request.query["key"])
                if event: event.set()
                return web.json_response({"released": event is not None})
            if kind == "outbound":
                async with ClientSession() as session:
                    async with session.get(_target_url(request.query["url"])) as response:
                        await response.read()
                        with tracer.trace("probe.after_outbound"): pass
                        return web.json_response({"status": response.status})
            if kind == "echo": return web.json_response(dict(request.headers))
            raise web.HTTPNotFound()

        _probe_run_app = web.run_app
        def _install_aio_probes(app):
            app.middlewares.insert(0, _aio_marker)
            if os.environ.get("RULES_STESTS_PROBES") == "true":
                app.router.add_route("*", "/__rules_stests/{kind}", _aio_probe)
            return app
        def _run_app_with_probes(app, *args, **kwargs):
            if asyncio.iscoroutine(app):
                pending = app
                async def resolved(): return _install_aio_probes(await pending)
                app = resolved()
            else: _install_aio_probes(app)
            return _probe_run_app(app, *args, **kwargs)
        web.run_app = _run_app_with_probes
    else:
        import django
        from ddtrace import patch
        patch(httplib=True)
        import importlib
        import types
        from django.db.backends.utils import CursorWrapper
        from django.conf import settings
        from django.http import JsonResponse
        from django.urls import path, clear_url_caches

        import sqlite3  # Complete the registered auto-instrumentation import hook first.
        from ddtrace.contrib.internal.sqlite3.patch import TracedSQLiteCursor
        from django.core.handlers.wsgi import WSGIHandler
        _cursor_execute = TracedSQLiteCursor.execute
        _cursor_executemany = TracedSQLiteCursor.executemany
        def _marked_execute(self, sql, *args, **kwargs): return _cursor_execute(self, _mark_sql(sql), *args, **kwargs)
        def _marked_executemany(self, sql, *args, **kwargs): return _cursor_executemany(self, _mark_sql(sql), *args, **kwargs)
        TracedSQLiteCursor.execute, TracedSQLiteCursor.executemany = _marked_execute, _marked_executemany

        # Outside Django's tracing middleware, so connection initialization and
        # authentication queries receive the same independent request marker.
        _wsgi_call = WSGIHandler.__call__
        def _marked_wsgi(self, environ, start_response):
            request_id = environ.get("HTTP_X_RULES_STESTS_REQUEST_ID")
            if not request_id or os.environ.get("RULES_STESTS_SQL_MARKERS") != "true":
                return _wsgi_call(self, environ, start_response)
            marker = _marker(request_id)
            token = _request_marker.set(marker)
            def marked_start(status, headers, exc_info=None):
                headers.append(("X-Rules-Stests-Sql-Marker", marker[1]))
                headers.append(("X-Rules-Stests-Sql-Count", str(marker[2])))
                return start_response(status, headers, exc_info)
            try: return _wsgi_call(self, environ, marked_start)
            finally: _request_marker.reset(token)
        WSGIHandler.__call__ = _marked_wsgi

        def _django_probe(request, kind):
            if kind == "exception":
                with tracer.trace("probe.exception"):
                    raise RuntimeError("controlled rules_stests exception")
            if kind in ("nested", "keep", "drop", "partial"):
                _probe_spans(kind)
                if kind == "partial":
                    key = request.GET["key"]
                    event = threading.Event()
                    with _held_lock: _held[key] = event
                    try:
                        if not event.wait(15): raise TimeoutError("partial probe was not released")
                    finally:
                        with _held_lock: _held.pop(key, None)
                return JsonResponse({"children":3})
            if kind == "state":
                with _held_lock: held = request.GET["key"] in _held
                return JsonResponse({"held": held})
            if kind == "release":
                with _held_lock: event = _held.get(request.GET["key"])
                if event: event.set()
                return JsonResponse({"released":event is not None})
            if kind == "outbound":
                import urllib.request
                with urllib.request.urlopen(_target_url(request.GET["url"])) as response:
                    response.read()
                    with tracer.trace("probe.after_outbound"): pass
                    return JsonResponse({"status":response.status})
            if kind == "echo": return JsonResponse(dict(request.headers))
            return JsonResponse({"error":"unknown probe"},status=404)

        _django_setup = django.setup
        def _setup_with_probes(*args, **kwargs):
            if os.environ.get("RULES_STESTS_SQL_MARKERS") == "true":
                for database in settings.DATABASES.values():
                    if database["ENGINE"] == "django.db.backends.sqlite3":
                        database.setdefault("OPTIONS", {}).update(timeout=30, transaction_mode="IMMEDIATE")
            result = _django_setup(*args, **kwargs)
            if os.environ.get("RULES_STESTS_PROBES") == "true":
                routes = importlib.import_module(settings.ROOT_URLCONF)
                if not getattr(routes, "_rules_stests_probes", False):
                    routes.urlpatterns.insert(0, path("__rules_stests/<str:kind>", _django_probe))
                    routes._rules_stests_probes = True
                    clear_url_caches()
            return result
        django.setup = _setup_with_probes
