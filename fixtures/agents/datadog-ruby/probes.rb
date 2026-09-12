# frozen_string_literal: true

# Opt-in probes shared by feature and parallel workloads. SQL markers are
# generated inside the application independently of the proxy's request IDs.
require "securerandom"
require "json"
require "net/http"

module RulesStestsDatadog
  @held = {}
  @held_mutex = Mutex.new
  class << self
    attr_reader :held, :held_mutex
    def marked_sql(sql)
      marker = Thread.current[:rules_stests_sql_marker]
      return sql unless marker && !sql.include?("/* rules_stests_request=")
      marker[2] += 1
      "#{sql} /* rules_stests_request=#{marker[0]}; marker=#{marker[1]} */"
    end
  end

  module SQLMarkers
    def internal_execute(sql, ...)
      super(RulesStestsDatadog.marked_sql(sql), ...)
    end
  end

  module CachedSQLMarkers
    def instrument(name, payload = {}, ...)
      if name == "sql.active_record" && payload[:sql]
        payload = payload.merge(sql: RulesStestsDatadog.marked_sql(payload[:sql]))
      end
      super(name, payload, ...)
    end
  end

  class Probes
    def initialize(app)
      @app = app
    end

    def call(env)
      request_id = env["HTTP_X_RULES_STESTS_REQUEST_ID"]
      marker = nil
      if request_id && ENV["RULES_STESTS_SQL_MARKERS"] == "true"
        raise ArgumentError, "invalid request identifier" unless /\A[0-9a-f]{32}\z/.match?(request_id)
        marker = [request_id, SecureRandom.hex(16), 0]
        Thread.current[:rules_stests_sql_marker] = marker
      end
      if ENV["RULES_STESTS_PROBES"] == "true" && env["PATH_INFO"].start_with?("/__rules_stests/")
        response = probe(env)
      else
        response = @app.call(env)
      end
      if marker
        response[1]["x-rules-stests-sql-marker"] = marker[1]
        response[1]["x-rules-stests-sql-count"] = marker[2].to_s
      end
      response
    ensure
      Thread.current[:rules_stests_sql_marker] = nil
    end

    def json(value, status = 200)
      [status, {"content-type" => "application/json"}, [JSON.generate(value)]]
    end

    def probe(env)
      kind = env["PATH_INFO"].split("/").last
      query = Rack::Utils.parse_query(env["QUERY_STRING"])
      case kind
      when "nested", "keep", "drop", "partial"
        Datadog::Tracing.trace("probe.parent", resource: kind) do
          Datadog::Tracing.keep! if kind == "keep"
          Datadog::Tracing.reject! if kind == "drop"
          3.times do |index|
            Datadog::Tracing.trace("probe.child", resource: index.to_s) { |span| span.set_tag("probe.index", index.to_s) }
          end
        end
        if kind == "partial"
          mutex, condition, released = Mutex.new, ConditionVariable.new, [false]
          event = [mutex, condition, released]
          RulesStestsDatadog.held_mutex.synchronize { RulesStestsDatadog.held[query.fetch("key")] = event }
          mutex.synchronize { condition.wait(mutex, 15) unless released[0] }
          RulesStestsDatadog.held_mutex.synchronize { RulesStestsDatadog.held.delete(query.fetch("key")) }
          raise "partial probe was not released" unless released[0]
        end
        json(children: 3)
      when "state", "release"
        event = RulesStestsDatadog.held_mutex.synchronize { RulesStestsDatadog.held[query.fetch("key")] }
        event[0].synchronize { event[2][0] = true; event[1].broadcast } if event && kind == "release"
        json(kind == "state" ? {held: !!event} : {released: !!event})
      when "exception"
        begin
          Datadog::Tracing.trace("probe.exception") { raise "controlled rules_stests exception" }
        rescue StandardError => error
          Datadog::Tracing.active_span&.set_error(error)
          json({error: error.message}, 500)
        end
      when "outbound"
        uri = URI(query.fetch("url"))
        raise "probe target must be loopback HTTP" unless uri.scheme == "http" && ["127.0.0.1", "localhost"].include?(uri.host)
        response = Net::HTTP.get_response(uri)
        Datadog::Tracing.trace("probe.after_outbound") {}
        json(status: response.code.to_i)
      when "echo"
        json(env.select { |key, _| key.start_with?("HTTP_") })
      else
        json({error: "unknown probe"}, 404)
      end
    end
  end

  class ProbeRailtie < Rails::Railtie
    initializer "rules_stests.datadog.probes", before: :build_middleware_stack do |app|
      ActiveRecord::ConnectionAdapters::AbstractAdapter.prepend(SQLMarkers)
      ActiveSupport::Notifications::Instrumenter.prepend(CachedSQLMarkers)
      app.middleware.use(Probes)
    end
  end
end
