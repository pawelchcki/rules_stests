# frozen_string_literal: true

# Application Bundler runs first and remains authoritative for shared gems.
# This payload never adds itself to the application's Gemfile or lockfile.
require "bundler/setup"
require "rbconfig"
require "json"

module RulesStestsDatadog
  def self.activate!
    return if @activated
    raise LoadError, "recursive Datadog activation" if @activating
    @activating = true
    root = File.expand_path(ENV.fetch("RULES_STESTS_DATADOG_RUBY_ROOT"))
    abi = JSON.parse(File.read(File.join(root, "abi.json")))
    actual = {"ruby_version" => RbConfig::CONFIG.fetch("ruby_version"), "arch" => RbConfig::CONFIG.fetch("arch")}
    raise LoadError, "Datadog Ruby ABI mismatch: expected #{abi}, got #{actual}" unless abi == actual
    specs = Dir[File.join(root, "specifications", "*.gemspec")].sort.to_h do |path|
      spec = Gem::Specification.load(path)
      raise LoadError, "invalid Datadog gem specification: #{path}" unless spec
      [spec.name, spec]
    end
    tracer = specs.fetch("datadog") { raise LoadError, "missing locked Datadog gem" }
    raise LoadError, "expected Datadog 2.42.0, got #{tracer.version}" unless tracer.version.to_s == "2.42.0"
    if (loaded = Gem.loaded_specs["datadog"]) && loaded.version != tracer.version
      raise LoadError, "incompatible already activated Datadog #{loaded.version}"
    end
    selected = {}
    visit = lambda do |spec|
      return if selected.key?(spec.name)
      selected[spec.name] = spec
      spec.runtime_dependencies.each do |dependency|
        candidate = Gem.loaded_specs[dependency.name] || specs[dependency.name]
        unless candidate && dependency.matches_spec?(candidate)
          raise LoadError, "incompatible or missing Datadog dependency #{dependency}; selected #{candidate&.version}"
        end
        visit.call(candidate)
      end
    end
    visit.call(tracer)
    selected.each_value do |spec|
      next if Gem.loaded_specs.key?(spec.name)
      if spec.missing_extensions? || (!spec.extensions.empty? && spec.full_require_paths.none? { |path| Dir[File.join(path, "**", "*.so")].any? })
        raise LoadError, "missing native extensions for Datadog dependency #{spec.full_name} (#{actual})"
      end
      spec.full_require_paths.each do |path|
        raise LoadError, "missing Datadog dependency load path: #{path}" unless File.directory?(path)
        $LOAD_PATH << path unless $LOAD_PATH.include?(path)
      end
      # Bundler's require hook consults activated metadata, not GEM_PATH.
      Gem.loaded_specs[spec.name] = spec
    end
    require "rails"
    require "active_record"
    require "action_controller/railtie"
    require "datadog/auto_instrument"
    if ENV["RULES_STESTS_PROBES"] == "true"
      Datadog.configure do |config|
        if (pattern = ENV["DD_TRACE_OBFUSCATION_QUERY_STRING_REGEXP"])
          config.tracing.instrument :rack, quantize: {query: {show: :all, obfuscate: {regex: Regexp.new(pattern)}}}
        end
        config.tracing.partial_flush.enabled = ENV["DD_TRACE_PARTIAL_FLUSH_ENABLED"] == "true"
        config.tracing.partial_flush.min_spans_threshold = Integer(ENV.fetch("DD_TRACE_PARTIAL_FLUSH_MIN_SPANS", "500"))
      end
    end
    if ENV["RULES_STESTS_PROBES"] == "true" || ENV["RULES_STESTS_SQL_MARKERS"] == "true"
      require File.join(root, "probes.rb")
    end
    @activated = true
  ensure
    @activating = false
  end
end

RulesStestsDatadog.activate!
