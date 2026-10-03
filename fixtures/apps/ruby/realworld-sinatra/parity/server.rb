# Test-only determinism: exercise the real HTTP server and database while
# keeping timestamp progression, token claims and collision suffixes equal.
require "securerandom"
class Time
  class << self
    attr_accessor :parity_tick
    def now
      Time.utc(2026, 1, 2, 3, 4, 5, 123456) + (parity_tick || 0)
    end
  end
end
module SecureRandom
  @parity_sequence = 0
  def self.hex(length = 16)
    @parity_sequence += 1
    "%0*x" % [length * 2, @parity_sequence]
  end
end
app = File.join(ENV.fetch("REALWORLD_BUNDLE_ROOT"), "src")
require File.realpath(File.join(app, "app", "realworld.rb"))
RealWorld::App.before do
  Time.parity_tick = Integer(env.fetch("HTTP_X_PARITY_TICK", "0"))
end
load File.join(app, "bin", "server")
