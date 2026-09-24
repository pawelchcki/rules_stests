"""Standalone OpenTelemetry API workload; no RealWorld routes or database."""

import argparse
import logging
import os
import time
from aiohttp import web
from opentelemetry import baggage, context, propagate, trace, metrics
from opentelemetry.trace import Link, SpanContext, TraceFlags, TraceState, Status, StatusCode
from opentelemetry.sdk._logs import LoggerProvider, LogRecordProcessor
from opentelemetry.sdk._logs.export import LogRecordExporter, LogRecordExportResult, SimpleLogRecordProcessor
from opentelemetry.propagators.textmap import Getter, Setter
from opentelemetry.exporter.prometheus import PrometheusMetricReader
from opentelemetry.sdk.metrics import MeterProvider as SDKMeterProvider
from opentelemetry.sdk.resources import Resource
from opentelemetry.sdk.trace import TracerProvider as SDKTracerProvider
from opentelemetry.sdk.trace.export import SpanExporter, SpanExportResult, SimpleSpanProcessor
from prometheus_client import CollectorRegistry, generate_latest


TRACER = trace.get_tracer("telemetry-lab.python", "1.0.0", schema_url="https://example.test/telemetry-lab/1")
METER = metrics.get_meter("telemetry-lab.python", "1.0.0", schema_url="https://example.test/telemetry-lab/1")
COUNTER = METER.create_counter("lab.requests", unit="{request}", description="Requests made to the lab")
UPDOWN = METER.create_up_down_counter("lab.active", unit="{request}", description="Active lab work")
HISTOGRAM = METER.create_histogram("lab.duration", unit="ms", description="Synthetic duration")


async def health(request):
    return web.json_response({"ready": True})


async def spans(request):
    link_context = SpanContext(
        trace_id=0x123456789ABCDEF0123456789ABCDEF0,
        span_id=0x123456789ABCDEF0,
        is_remote=True,
        trace_flags=TraceFlags(TraceFlags.SAMPLED),
        trace_state=TraceState(),
    )
    next_link_context = SpanContext(
        trace_id=0x123456789ABCDEF0123456789ABCDEF1,
        span_id=0x123456789ABCDEF1,
        is_remote=True,
        trace_flags=TraceFlags(TraceFlags.SAMPLED),
        trace_state=TraceState(),
    )
    with TRACER.start_as_current_span(
        "lab.parent", links=[Link(link_context, attributes={"lab.link": "first", "lab.extra": "one"}),
                             Link(next_link_context, attributes={"lab.link": "second", "lab.extra": "two"})],
        attributes={
            "lab.string": "visible", "lab.boolean": True, "lab.integer": 42,
            "lab.double": 3.5, "lab.array": ["red", "blue"],
        },
    ) as parent:
        assert trace.get_current_span() is parent
        parent.add_event("lab.first", {"lab.order": 1, "lab.event.extra": "kept-or-dropped"})
        parent.add_link(link_context, {"lab.link": "after-start", "lab.extra": "three"})
        with TRACER.start_as_current_span("lab.child") as child:
            child.set_attribute("lab.updated", "after-start")
            child.update_name("lab.child.renamed")
            child.set_status(Status(StatusCode.OK))
        manual = TRACER.start_span("lab.manually-active")
        manual_token = context.attach(trace.set_span_in_context(manual))
        try:
            assert trace.get_current_span() is manual
        finally:
            context.detach(manual_token)
            manual.end()
        parent.add_event("lab.second", {"lab.order": 2})
        COUNTER.add(1, {"lab.route": "spans"})
        HISTOGRAM.record(12.5, {"lab.route": "spans"})
        logging.getLogger("telemetry-lab.python").warning(
            "lab span request", extra={"lab_long": "abcdefghijklmnop", "lab_second": "present"}
        )
        return web.json_response({"recording": parent.is_recording(), "trace_id": format(parent.get_span_context().trace_id, "032x")})


async def exception(request):
    with TRACER.start_as_current_span("lab.exception") as span:
        try:
            raise ValueError("controlled lab error")
        except ValueError as error:
            span.record_exception(error, attributes={"lab.handled": True})
            span.set_status(Status(StatusCode.ERROR, "controlled lab error"))
    return web.json_response({"handled": True})


async def span_lifecycle(request):
    start = time.time_ns() - 100_000_000
    end = start + 50_000_000
    span = TRACER.start_span("lab.lifecycle", start_time=start)
    before = span.is_recording()
    span.end(end_time=end)
    after = span.is_recording()
    key = context.create_key("telemetry-lab-key")
    updated = context.set_value(key, "attached-value")
    token = context.attach(updated)
    try:
        attached = context.get_value(key, context.get_current())
    finally:
        context.detach(token)
    detached = context.get_value(key)
    return web.json_response({"before": before, "after": after, "start": start,
                              "end": end, "attached": attached, "detached": detached})


async def measurements(request):
    UPDOWN.add(1, {"lab.route": "metrics"})
    try:
        with TRACER.start_as_current_span("lab.measurement"):
            COUNTER.add(2, {"lab.route": "metrics"})
            HISTOGRAM.record(7.25, {"lab.route": "metrics"})
    finally:
        UPDOWN.add(-1, {"lab.route": "metrics"})
    return web.json_response({"measured": True})


async def propagation(request):
    extracted = propagate.extract(request.headers)
    remote_parent = trace.get_current_span(extracted).get_span_context().is_remote
    token = context.attach(baggage.set_baggage("lab-key", "lab-value", extracted))
    try:
        with TRACER.start_as_current_span("lab.propagated") as span:
            carrier = {}
            propagate.inject(carrier)
            return web.json_response({
                "remote_parent": remote_parent,
                "baggage": baggage.get_baggage("lab-key"),
                "carrier": carrier,
            })
    finally:
        context.detach(token)


class LabGetter(Getter):
    def __init__(self):
        self.calls = []

    def get(self, carrier, key):
        self.calls.append(key)
        value = carrier.get(key)
        return [value] if value is not None else None

    def keys(self, carrier):
        return list(carrier)


class LabSetter(Setter):
    def __init__(self):
        self.calls = []

    def set(self, carrier, key, value):
        self.calls.append(key)
        carrier[key] = value


async def propagation_custom(request):
    incoming = {"traceparent": "00-0123456789abcdef0123456789abcdef-0123456789abcdef-01",
                "baggage": "incoming=value"}
    getter = LabGetter()
    extracted = propagate.extract(incoming, getter=getter)
    remote = trace.get_current_span(extracted).get_span_context().is_remote
    setter = LabSetter()
    outgoing = {}
    environment_carrier = dict(os.environ)
    token = context.attach(extracted)
    try:
        propagate.inject(outgoing, setter=setter)
        propagate.inject(environment_carrier)
    finally:
        context.detach(token)
    environment_remote = trace.get_current_span(propagate.extract(environment_carrier)).get_span_context().is_remote
    return web.json_response({"remote": remote, "get_calls": getter.calls,
                              "keys": getter.keys(incoming), "set_calls": setter.calls,
                              "outgoing": outgoing, "environment_remote": environment_remote,
                              "environment_traceparent": environment_carrier.get("traceparent")})


class LabLogExporter(LogRecordExporter):
    def __init__(self):
        self.records = []
        self.shut = False

    def export(self, batch):
        self.records.extend(batch)
        return LogRecordExportResult.SUCCESS

    def force_flush(self, timeout_millis=10_000):
        return True

    def shutdown(self):
        self.shut = True


class LabSpanExporter(SpanExporter):
    def __init__(self):
        self.spans = []
        self.flushed = False
        self.shut = False

    def export(self, spans):
        self.spans.extend(spans)
        return SpanExportResult.SUCCESS

    def force_flush(self, timeout_millis=30_000):
        self.flushed = True
        return True

    def shutdown(self):
        self.shut = True


class LabLogProcessor(LogRecordProcessor):
    def __init__(self):
        self.emitted = 0
        self.flushed = False
        self.shut = False

    def on_emit(self, log_record):
        self.emitted += 1

    def force_flush(self, timeout_millis=30_000):
        self.flushed = True
        return True

    def shutdown(self):
        self.shut = True


async def log_sdk(request):
    provider = LoggerProvider(shutdown_on_exit=False)
    exporter = LabLogExporter()
    processor = LabLogProcessor()
    provider.add_log_record_processor(SimpleLogRecordProcessor(exporter))
    provider.add_log_record_processor(processor)
    logger = provider.get_logger("lab.custom.log", attributes={"lab.scope": "logged"})
    logger.emit(body="lab direct log", attributes={"lab.kind": "direct"})
    count = len(exporter.records)
    record = exporter.records[0] if count else None
    scope_name = record.instrumentation_scope.name if record else ""
    scope_attribute = record.instrumentation_scope.attributes.get("lab.scope") if record else None
    body = record.log_record.body if record else None
    exporter_flushed = exporter.force_flush()
    flushed = provider.force_flush()
    provider.shutdown()
    return web.json_response({"count": count, "scope_name": scope_name,
                              "scope_attribute": scope_attribute, "body": body,
                              "processor_emitted": processor.emitted,
                              "processor_flushed": processor.flushed,
                              "processor_shutdown": processor.shut,
                              "exporter_shutdown": exporter.shut, "exporter_flushed": exporter_flushed,
                              "provider_flushed": flushed})


async def trace_exporter(request):
    exporter = LabSpanExporter()
    provider = SDKTracerProvider(shutdown_on_exit=False)
    provider.add_span_processor(SimpleSpanProcessor(exporter))
    with provider.get_tracer("lab.custom.trace").start_as_current_span("lab.exported"):
        pass
    flushed = exporter.force_flush()
    count = len(exporter.spans)
    name = exporter.spans[0].name if count else None
    provider.shutdown()
    return web.json_response({"count": count, "name": name, "flushed": flushed,
                              "exporter_flushed": exporter.flushed, "shutdown": exporter.shut})


async def prometheus(request):
    registry = CollectorRegistry()
    reader = PrometheusMetricReader(registry=registry)
    provider = SDKMeterProvider(metric_readers=[reader], resource=Resource.create({"service.name": "lab-prom", "lab.resource": "yes"}))
    meter = provider.get_meter("lab.prom.scope", "1.2.3")
    counter = meter.create_counter("lab.requests", description="Lab requests")
    active = meter.create_up_down_counter("lab.active", description="Active lab requests")
    gauge = meter.create_gauge("lab.temperature", description="Lab temperature")
    histogram = meter.create_histogram("lab.duration", unit="ms", description="Lab duration")
    counter.add(2, {"lab.route": "one"})
    counter.add(3, {"lab.route": "one"})
    active.add(2, {"lab.route": "one"})
    active.add(-1, {"lab.route": "one"})
    gauge.set(21, {"lab.route": "one"})
    histogram.record(12, {"lab.route": "one"})
    rendered = generate_latest(registry).decode("utf-8")
    provider.shutdown()
    return web.json_response({"text": rendered})


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, required=True)
    args = parser.parse_args()
    app = web.Application()
    app.router.add_get("/healthz", health)
    app.router.add_get("/v1/spans", spans)
    app.router.add_get("/v1/exceptions", exception)
    app.router.add_get("/v1/lifecycle", span_lifecycle)
    app.router.add_get("/v1/metrics", measurements)
    app.router.add_get("/v1/propagation", propagation)
    app.router.add_get("/v1/propagation-custom", propagation_custom)
    app.router.add_get("/v1/log-sdk", log_sdk)
    app.router.add_get("/v1/trace-exporter", trace_exporter)
    app.router.add_get("/v1/prometheus", prometheus)
    web.run_app(app, host=args.host, port=args.port, print=None)


if __name__ == "__main__":
    main()
