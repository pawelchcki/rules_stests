require_relative "boot"
require "rails"
require "active_model/railtie"
require "active_record/railtie"
require "action_controller/railtie"

Bundler.require(*Rails.groups)

module RealworldRails
  class Application < Rails::Application
    config.load_defaults 8.1
    config.api_only = true
    config.autoload_lib(ignore: %w[assets tasks])
    config.hosts.clear
    config.secret_key_base = ENV.fetch("SECRET_KEY_BASE", "rules-stests-development-only-secret-key-base")
  end
end
