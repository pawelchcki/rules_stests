# frozen_string_literal: true

# Independent Rack workload running against the pinned bundled Ruby and agent.
require "json"
require "rack"
require "puma"
require "opentelemetry-api"

tracer = OpenTelemetry.tracer_provider.tracer("telemetry-lab.ruby", "1.0.0")
app = proc do |environment|
  path = environment.fetch("PATH_INFO")
  headers = { "content-type" => "application/json" }
  payload = case path
  when "/healthz"
    { ready: true }
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
