"""Controlled ddtrace SDK workload for native propagation and sampling checks."""
import argparse
import json
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import parse_qs, urlsplit

from ddtrace import tracer
from ddtrace.propagation.http import HTTPPropagator


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        route = urlsplit(self.path)
        if route.path == "/healthz":
            self.send_json({"ready": True})
            return
        if route.path != "/run":
            self.send_error(404)
            return
        query = parse_qs(route.query)
        service = query.get("service", ["lab-service"])[0]
        name = query.get("name", ["lab.request"])[0]
        with tracer.trace(name, service=service) as root:
            with tracer.trace("lab.child", service="lab-child") as child:
                child_id = child.span_id
                child_parent_id = child.parent_id
            carrier = {}
            HTTPPropagator.inject(root.context, carrier)
            result = {
                "trace_id": str(root.trace_id),
                "root_id": str(root.span_id),
                "root_parent_id": str(root.parent_id or 0),
                "child_id": str(child_id),
                "child_parent_id": str(child_parent_id),
                "service": service,
                "name": name,
                "carrier": carrier,
                "priority": root.context.sampling_priority,
            }
        tracer.flush()
        self.send_json(result)

    def send_json(self, value):
        body = json.dumps(value, sort_keys=True).encode()
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, fmt, *args):
        pass


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--ready-file", required=True)
    args = parser.parse_args()
    server = ThreadingHTTPServer(("127.0.0.1", 0), Handler)
    ready = Path(args.ready_file)
    temporary = ready.with_name(ready.name + ".tmp")
    temporary.write_text(str(server.server_address[1]), encoding="ascii")
    temporary.replace(ready)
    server.serve_forever()
