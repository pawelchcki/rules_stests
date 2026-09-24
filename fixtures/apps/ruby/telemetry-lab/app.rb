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
      "lab.double" => 3.5, "lab.array" => ["red", "blue"]
    }) do |parent|
      parent.add_event("lab.first", attributes: { "lab.order" => 1 })
      tracer.in_span("lab.child") do |child|
        child.set_attribute("lab.updated", "after-start")
        child.name = "lab.child.renamed"
        child.status = OpenTelemetry::Trace::Status.ok
      end
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
