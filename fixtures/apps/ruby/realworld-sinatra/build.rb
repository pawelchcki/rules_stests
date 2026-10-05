require "rubygems"
require "rubygems/package"
require "fileutils"
require "json"

app = ARGV.shift
inputs = JSON.parse(File.read(File.join(app, "build-inputs.json")))
runtime = inputs.fetch("runtime")
abort("wrong Ruby version") unless RUBY_VERSION == runtime.fetch("version")
abort("wrong Ruby patchlevel") if runtime.key?("patchlevel") && RUBY_PATCHLEVEL != runtime.fetch("patchlevel")
gem_root = File.join(app, "bundle", "ruby", runtime.fetch("abi"))
FileUtils.mkdir_p(File.join(gem_root, "specifications"))
until ARGV.empty?
  name, archive = ARGV.shift, ARGV.shift
  spec = if Gem::Package.respond_to?(:new)
    Gem::Package.new(archive).spec
  else
    require "rubygems/format"
    Gem::Format.from_file_by_path(archive).spec
  end
  abort("gem identity mismatch: #{name}") unless "#{spec.name}-#{spec.version}" == name
  path = File.join(gem_root, "specifications", "#{name}.gemspec")
  File.open(path, "w") { |file| file.write(spec.to_ruby) }
  spec.loaded_from = path
  if !spec.extensions.empty? && spec.respond_to?(:extension_dir)
    FileUtils.mkdir_p(spec.extension_dir)
    File.open(File.join(spec.extension_dir, "gem.build_complete"), "w") {}
  end
end
Gem::Specification.reset if Gem::Specification.respond_to?(:reset)
inputs.fetch("gems").each { |item| gem(item.fetch("name"), "= #{item.fetch('version')}") }
inputs.fetch("gems").each do |item|
  spec = Gem.loaded_specs.fetch(item.fetch("name"))
  abort("unsupported Ruby for #{spec.name}") unless spec.required_ruby_version.satisfied_by?(Gem::Version.new(RUBY_VERSION.dup))
  spec.runtime_dependencies.each do |dependency|
    loaded = Gem.loaded_specs[dependency.name]
    abort("unlocked dependency: #{dependency}") unless loaded && dependency.requirement.satisfied_by?(loaded.version)
  end
end

if inputs.key?("telemetry")
  require "google/protobuf"
  require "opentelemetry/sdk"
  require "opentelemetry/exporter/otlp"
  require "opentelemetry/instrumentation/rack"
  require "opentelemetry/instrumentation/sinatra"
  abort("wrong telemetry SDK") unless OpenTelemetry::SDK::VERSION == inputs.fetch("telemetry").fetch("sdkVersion")
end

ENV["DATABASE_PATH"] = File.join(app, "seed", "contract.sqlite3")
load File.join(app, "src", "bin", "setup-database")
load File.join(app, "src", "test", "contract.rb")
RealWorld::DB.disconnect
FileUtils.rm_f(ENV["DATABASE_PATH"])
RealWorld::DB.opts[:database] = File.join(app, "seed", "realworld.sqlite3")
RealWorld::SCHEMA.call(RealWorld::DB)
RealWorld::DB.run("VACUUM")
RealWorld::DB.disconnect
