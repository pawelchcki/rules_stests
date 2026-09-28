# RealWorld on Sinatra, Sequel, and Falcon

An async Ruby implementation of the RealWorld API with the same observable
behavior as `../realworld-rails`: identical routes, status codes, and error
messages. `bin/server` runs Falcon inside the process. Four threads each run an
Async reactor over one bound socket, and every request runs in its own fiber,
so concurrent requests interleave across threads and fibers. Sequel checks out
database connections per fiber and binds every SQL value, so traced SQL keeps
its placeholders and is identical from run to run.

`test/realworld_contract_test.rb` runs against a fresh database during the
image build. `oci/README.md` describes the image.
