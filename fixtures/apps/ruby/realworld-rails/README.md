# Rails RealWorld API corpus fixture

This repository-owned Rails 8.1 API implements the pinned RealWorld contract
used by `@realworld_api_specs`. It intentionally has no dependency on archived
third-party RealWorld server code. SQLite uniqueness, foreign-key, and check
constraints back the model validations, and writes spanning relationships are
transactional.

Run locally with Ruby 3.3.12:

```sh
bundle install
bin/rails db:prepare
bin/rails test
bin/rails server
```
