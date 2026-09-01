# frozen_string_literal: true

root = ENV.fetch("OTEL_RUBY_ADDITIONAL_GEM_PATH")
hook = File.join(root, "vendor", "opentelemetry-ruby-instrumentation", "lib", "opentelemetry-auto-instrumentation.rb")
raise LoadError, "OpenTelemetry Ruby activation source is missing: #{hook}" unless File.file?(hook)

# Load the application's framework entrypoints before the distro configures
# instrumentation. This keeps the application bundle unchanged while making
# the Rails component Railties available early enough to install middleware.
require "bundler/setup"
require "rails"
require "active_record"
require "action_controller/railtie"
require hook
OTelBundlerPatch::OTelInitializer._otel_require_otel

module OpenTelemetryRubyAutoInstrumentation
  module RailsLoggerBridge
    SEVERITY_NUMBERS = [5, 9, 13, 17, 21, 0].freeze
    SEVERITY_TEXT = %w[DEBUG INFO WARN ERROR FATAL UNKNOWN].freeze

    def add(severity, message = nil, progname = nil, &block)
      captured = nil
      wrapped = block && proc { captured = block.call }
      result = super(severity, message, progname, &wrapped)
      body = message || captured || progname
      if body && severity >= level
        OpenTelemetry.logger_provider.logger(name: "Ruby::Logger", version: RUBY_VERSION).on_emit(
          timestamp: Time.now,
          severity_number: SEVERITY_NUMBERS.fetch(severity, 0),
          severity_text: SEVERITY_TEXT.fetch(severity, "UNKNOWN"),
          body: body.to_s
        )
      end
      result
    end
  end

  class RailsLoggerRailtie < ::Rails::Railtie
    initializer "opentelemetry-ruby-auto-instrumentation.logger", after: :initialize_logger do
      logger = ::Rails.logger
      targets = logger.respond_to?(:broadcasts) ? logger.broadcasts : [logger]
      targets.each do |target|
        target.singleton_class.prepend(RailsLoggerBridge) unless target.singleton_class < RailsLoggerBridge
      end
    end
  end
end
