# Patched OpenTelemetry Ruby auto-instrumentation payload

This single-payload image contains the official `0.1.0` source from commit
`5e1c2b7c5b30877f957ae555029275114b23a14d` and its checksummed transitive gem
set, compiled for the Ruby 3.3 ABI used by the Rails fixture.

`activation.rb` is a repository-owned patch layer, not upstream source. It
preloads the Rails framework entrypoints before invoking the official hook so
the Rack and Action Pack Railties install in time, and it bridges Rails'
underlying Ruby `Logger` records into the OpenTelemetry Logs SDK. The vendored
upstream implementation remains byte-for-byte unchanged.

The corpus launcher validates `activation.rb`, sets
`OTEL_RUBY_ADDITIONAL_GEM_PATH` to the extracted payload, and prepends the hook
to `RUBYOPT`. The application Gemfile and bundle remain unchanged.
