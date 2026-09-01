threads_count = Integer(ENV.fetch("RAILS_MAX_THREADS", 5))
threads threads_count, threads_count
bind "tcp://#{ENV.fetch('HOST', '0.0.0.0')}:#{ENV.fetch('PORT', '8000')}"
environment ENV.fetch("RAILS_ENV", "production")
workers 0
