# The SDK, exporter, Rack and Sinatra instrumentation are official, checksum-
# pinned gems selected for this interpreter in telemetry.lock.json.
require "opentelemetry/sdk"
require "opentelemetry/exporter/otlp"
require "opentelemetry/instrumentation/rack"
require "opentelemetry/instrumentation/sinatra"

module RealWorldTelemetry
  def self.configure
    OpenTelemetry::SDK.configure do |config|
      config.service_name = ENV.fetch("OTEL_SERVICE_NAME")
      config.resource = OpenTelemetry::SDK::Resources::Resource.create(
        "process.runtime.name" => "ruby",
        "process.runtime.version" => RUBY_VERSION,
        "process.runtime.description" => RUBY_DESCRIPTION,
        "process.pid" => Process.pid,
        "process.command" => "realworld-sinatra"
      )
      # Export before a request ends so the scenario receipt includes all its
      # spans without a time-based batch flush or a synthetic canary span.
      config.add_span_processor(OpenTelemetry::SDK::Trace::Export::SimpleSpanProcessor.new(
        OpenTelemetry::Exporter::OTLP::Exporter.new(compression: "none")
      ))
      config.use "OpenTelemetry::Instrumentation::Sinatra"
    end
    at_exit { OpenTelemetry.tracer_provider.shutdown }
  end

  # Sequel has no official instrumentation gem. This application hook uses the
  # official SDK to put actual prepared SQL execution under its request span.
  # SQL bindings stay outside attributes, keeping passwords and tokens out.
  def self.instrument_database(database)
    database.singleton_class.class_eval do
      alias_method :realworld_untraced_query, :log_connection_yield
      define_method(:log_connection_yield) do |sql, connection, args = nil, &operation|
        unless OpenTelemetry::Trace.current_span.recording?
          next realworld_untraced_query(sql, connection, args, &operation)
        end
        tracer = OpenTelemetry.tracer_provider.tracer("RealWorld::Sequel", "1.0.0")
        tracer.in_span("SQLite " + sql.split.first.to_s, kind: :client,
          attributes: {"db.system" => "sqlite", "db.statement" => sql}) do
          realworld_untraced_query(sql, connection, args, &operation)
        end
      end
    end
  end
end
