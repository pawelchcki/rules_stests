# frozen_string_literal: true

# Independent Rack workload running against the pinned bundled Ruby and agent.
require "json"
require "rack"
require "puma"
require "opentelemetry-api"
require "opentelemetry-sdk"

class LabIdGenerator
  attr_reader :roots, :spans

  def initialize
    @roots = 0
    @spans = 0
  end

  def generate_trace_id
    @roots += 1
    ["0102030405060708090a0b0c0d0e0f10"].pack("H*")
  end

  def generate_span_id
    @spans += 1
    [@spans].pack("Q>")
  end
end

def lab_trace_context
  wire = OpenTelemetry::Trace::Propagation::TraceContext::TextMapPropagator.new
  empty = OpenTelemetry::Context.empty
  parent_context = wire.extract({
    "traceparent" => "00-0123456789abcdef0123456789abcdef-0123456789abcdef-01",
    "tracestate" => "lab=upstream"
  }, context: empty)
  parent = OpenTelemetry::Trace.current_span(parent_context).context
  invalid = {
    "zero-trace" => "00-00000000000000000000000000000000-0123456789abcdef-01",
    "zero-span" => "00-0123456789abcdef0123456789abcdef-0000000000000000-01",
    "short" => "00-0123456789abcdef-0123456789abcdef-01",
    "non-hex" => "00-zz23456789abcdef0123456789abcdef-0123456789abcdef-01",
    "uppercase" => "00-0123456789ABCDEF0123456789abcdef-0123456789abcdef-01",
    "version-ff" => "ff-0123456789abcdef0123456789abcdef-0123456789abcdef-01"
  }.transform_values { |header| OpenTelemetry::Trace.current_span(wire.extract({ "traceparent" => header }, context: empty)).context.valid? }
  validity = {
    "valid" => [parent.trace_id, parent.span_id],
    "zero-trace" => [OpenTelemetry::Trace::INVALID_TRACE_ID, parent.span_id],
    "zero-span" => [parent.trace_id, OpenTelemetry::Trace::INVALID_SPAN_ID],
    "zero-both" => [OpenTelemetry::Trace::INVALID_TRACE_ID, OpenTelemetry::Trace::INVALID_SPAN_ID]
  }.transform_values { |ids| OpenTelemetry::Trace::SpanContext.new(trace_id: ids[0], span_id: ids[1]).valid? }
  generator = LabIdGenerator.new
  exporter = OpenTelemetry::SDK::Trace::Export::InMemorySpanExporter.new
  provider = OpenTelemetry::SDK::Trace::TracerProvider.new(id_generator: generator,
    sampler: OpenTelemetry::SDK::Trace::Samplers.parent_based(root: OpenTelemetry::SDK::Trace::Samplers::ALWAYS_ON))
  provider.add_span_processor(OpenTelemetry::SDK::Trace::Export::SimpleSpanProcessor.new(exporter))
  begin
    tracer = provider.tracer("lab.context")
    root = tracer.start_span("lab.generated.root", with_parent: empty)
    root_context = OpenTelemetry::Trace.context_with_span(root, parent_context: empty)
    child = tracer.start_span("lab.generated.child", with_parent: root_context)
    child.finish
    root.finish
    remote_child = tracer.start_span("lab.remote.child", with_parent: parent_context)
    outgoing = {}
    wire.inject(outgoing, context: OpenTelemetry::Trace.context_with_span(remote_child, parent_context: parent_context))
    remote_child.finish
    contexts = { "lab.generated.root" => root.context, "lab.generated.child" => child.context, "lab.remote.child" => remote_child.context }
    spans = exporter.finished_spans.map do |span|
      { name: span.name, trace_id: span.hex_trace_id, span_id: span.hex_span_id,
        remote: contexts.fetch(span.name).remote?, parent_id: span.hex_parent_span_id,
        parent_remote: span.parent_span_is_remote }
    end
    { validity: validity, invalid_headers: invalid, parent_remote: parent.remote?, parent_valid: parent.valid?,
      outgoing: outgoing, spans: spans, generated_roots: generator.roots, generated_spans: generator.spans,
      expected_failures: {
        "trace-invalid-headers" => {
          error: "invalid uppercase traceparent was accepted",
          reason: "Ruby OpenTelemetry SDK 1.11.0 accepts uppercase hexadecimal trace IDs in traceparent"
        }
      } }
  ensure
    provider.shutdown
  end
end

def lab_trace_limits
  limits = OpenTelemetry::SDK::Trace::SpanLimits.new(attribute_count_limit: 2, attribute_length_limit: 32,
    event_count_limit: 2, link_count_limit: 2, event_attribute_count_limit: 1, link_attribute_count_limit: 1)
  exporter = OpenTelemetry::SDK::Trace::Export::InMemorySpanExporter.new
  provider = OpenTelemetry::SDK::Trace::TracerProvider.new(span_limits: limits,
    sampler: OpenTelemetry::SDK::Trace::Samplers::ALWAYS_ON)
  provider.add_span_processor(OpenTelemetry::SDK::Trace::Export::SimpleSpanProcessor.new(exporter))
  begin
    tracer = provider.tracer("lab.limits")
    values = tracer.start_span("lab.values", with_parent: OpenTelemetry::Context.empty, attributes: {
      "lab.text" => "κόσμος" * 6, "lab.array" => ["abcdefghijklmnopqrstuvwxyz" * 2, "κόσμος" * 6, "short"]
    })
    values.finish
    span = tracer.start_span("lab.limits", with_parent: OpenTelemetry::Context.empty, attributes: {
      "lab.first" => 1, "lab.second" => 2, "lab.third" => 3
    })
    span.set_attribute("lab.fourth", 4)
    3.times do |index|
      span.add_event("event.#{index}", attributes: { "lab.first" => index, "lab.second" => index })
      link_context = OpenTelemetry::Trace::SpanContext.new(trace_id: ["01" + "00" * 15].pack("H*"),
        span_id: [index + 1, 0, 0, 0, 0, 0, 0, 0].pack("C*"))
      span.add_link(OpenTelemetry::Trace::Link.new(link_context, { "lab.first" => index, "lab.second" => index }))
    end
    span.finish
    value_data, data = exporter.finished_spans
    { value_attributes: value_data.attributes, attribute_count: data.attributes.size,
      dropped_attributes: data.total_recorded_attributes - data.attributes.size,
      dropped_events: data.total_recorded_events - data.events.size,
      dropped_links: data.total_recorded_links - data.links.size,
      events: data.events.map { |event| { name: event.name, index: event.name.split(".").last.to_i, attributes: event.attributes } },
      links: data.links.map { |link| { span_id: link.span_context.hex_span_id, index: link.span_context.span_id.bytes.first - 1, attributes: link.attributes } } }
  ensure
    provider.shutdown
  end
end

tracer = OpenTelemetry.tracer_provider.tracer("telemetry-lab.ruby", "1.0.0")
app = proc do |environment|
  path = environment.fetch("PATH_INFO")
  headers = { "content-type" => "application/json" }
  payload = case path
  when "/healthz"
    { ready: true }
  when "/v1/trace-context"
    lab_trace_context
  when "/v1/trace-limits"
    lab_trace_limits
  when "/v1/spans"
    tracer.in_span("lab.parent", attributes: {
      "lab.string" => "visible", "lab.boolean" => true, "lab.integer" => 42,
      "lab.double" => 3.5, "lab.array" => ["red", "blue"],
      "lab.ümlaut" => "κόσμος"
    }) do |parent|
      parent.add_event("lab.first", attributes: { "lab.order" => 1 })
      child_context = nil
      tracer.in_span("lab.child") do |child|
        child_context = child.context
        child.set_attribute("lab.updated", "after-start")
        child.name = "lab.child.renamed"
        child.status = OpenTelemetry::Trace::Status.ok
      end
      first_link = OpenTelemetry::Trace::Link.new(parent.context)
      second_link = OpenTelemetry::Trace::Link.new(child_context)
      linked = tracer.start_span("lab.linked", links: [first_link, second_link])
      linked.add_link(first_link)
      linked.finish
      parent.add_event("lab.second", attributes: { "lab.order" => 2 })
    end
    { spans: true }
  when "/v1/exceptions"
    tracer.in_span("lab.exception") do |span|
      begin
        raise ArgumentError, "controlled lab error"
      rescue ArgumentError => error
        span.record_exception(error, attributes: { "lab.handled" => true })
        span.status = OpenTelemetry::Trace::Status.error("controlled lab error")
      end
    end
    { handled: true }
  when "/v1/baggage"
    context = OpenTelemetry::Baggage.set_value("lab-key", "lab-value")
    { baggage: OpenTelemetry::Baggage.value("lab-key", context: context) }
  when "/v1/lifecycle"
    key = OpenTelemetry::Context.create_key("lab-lifecycle")
    before = OpenTelemetry::Context.value(key)
    context = OpenTelemetry::Context.current.set_value(key, "attached-value")
    token = OpenTelemetry::Context.attach(context)
    attached = OpenTelemetry::Context.current.value(key)
    OpenTelemetry::Context.detach(token)
    detached = OpenTelemetry::Context.value(key)

    start_time = Time.at(1_700_000_000, 123_000, :microsecond)
    end_time = start_time + 0.05
    span = tracer.start_span("lab.lifecycle", start_timestamp: start_time)
    recording_before = span.recording?
    current_before = OpenTelemetry::Trace.current_span.context.span_id
    active = nil
    tracer_span = nil
    OpenTelemetry::Trace.with_span(span) do
      active = OpenTelemetry::Trace.current_span.context.span_id
      tracer.in_span("lab.lifecycle.child") do
        tracer_span = OpenTelemetry::Trace.current_span.context.span_id
      end
    end
    current_after = OpenTelemetry::Trace.current_span.context.span_id
    span.finish(end_timestamp: end_time)
    {
      context_before: before, context_attached: attached, context_detached: detached,
      recording_before: recording_before, recording_after: span.recording?,
      active: active.unpack1("H*"), tracer_span: tracer_span.unpack1("H*"),
      restored: current_after == current_before
    }
  else
    nil
  end
  if payload
    [200, headers, [JSON.generate(payload)]]
  else
    [404, headers, [JSON.generate(error: "unknown probe")]]
  end
end

port_index = ARGV.index("--port")
raise ArgumentError, "--port is required" unless port_index && ARGV[port_index + 1]
port = Integer(ARGV[port_index + 1])
server = Puma::Server.new(app)
server.add_tcp_listener("127.0.0.1", port)
server.run
sleep
