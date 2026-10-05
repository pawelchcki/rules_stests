# encoding: utf-8
# Run against a fresh database inside every version-specific Bazel app build.
require "rack/mock"
require_relative "../app/realworld"

def assert_equal(expected, actual)
  raise "expected #{expected.inspect}, got #{actual.inspect}" unless expected == actual
end

def request(method, path, body = nil, token = nil)
  options = {"CONTENT_TYPE" => "application/json", :input => body ? JSON.generate(body) : ""}
  options["HTTP_AUTHORIZATION"] = "Token #{token}" if token
  response = Rack::MockRequest.new(RealWorld::App).request(method, path, options)
  [response.status, response.body.empty? ? nil : JSON.parse(response.body)]
end

def register(name)
  status, body = request("POST", "/api/users", {user: {username: name, email: "#{name}@example.com", password: "password123"}})
  assert_equal(201, status)
  body.fetch("user").fetch("token")
end

assert_equal([401, {"errors" => {"token" => ["is missing"]}}], request("GET", "/api/user"))
assert_equal([401, {"errors" => {"token" => ["is invalid"]}}], request("GET", "/api/user", nil, "junk"))
assert_equal([422, {"errors" => {"user" => ["is missing"]}}], request("POST", "/api/users", {}))
author, reader = register("author"), register("reader")
status, body = request("POST", "/api/articles", {article: {title: "Hello World", description: "d", body: "café 日本語", tagList: ["b", "a"]}}, author)
assert_equal(201, status)
slug = body.fetch("article").fetch("slug")
assert_equal("hello-world", slug)
assert_equal("café 日本語", body.fetch("article").fetch("body"))
assert_equal(["b", "a"], body.fetch("article").fetch("tagList"))
status, body = request("GET", "/api/articles?limit=0")
assert_equal(200, status)
assert_equal([], body.fetch("articles"))
assert_equal(1, body.fetch("articlesCount"))
assert_equal([], request("GET", "/api/articles?limit=-1&offset=-2").last.fetch("articles"))
assert_equal(403, request("DELETE", "/api/articles/#{slug}", nil, reader).first)
2.times { request("POST", "/api/articles/#{slug}/favorite", nil, reader) }
assert_equal(1, request("GET", "/api/articles/#{slug}").last.fetch("article").fetch("favoritesCount"))
status, body = request("POST", "/api/articles/#{slug}/comments", {comment: {body: "nice"}}, reader)
assert_equal(201, status)
comment = body.fetch("comment").fetch("id")
assert_equal(403, request("DELETE", "/api/articles/#{slug}/comments/#{comment}", nil, author).first)
assert_equal(204, request("DELETE", "/api/articles/#{slug}/comments/#{comment}", nil, reader).first)
2.times { request("POST", "/api/profiles/author/follow", nil, reader) }
assert_equal(1, request("GET", "/api/articles/feed?limit=1", nil, reader).last.fetch("articlesCount"))
assert_equal(1, request("GET", "/api/articles?tag=a").last.fetch("articlesCount"))
assert_equal(204, request("DELETE", "/api/articles/#{slug}", nil, author).first)
assert_equal(["b", "a"], request("GET", "/api/tags").last.fetch("tags"))
status, body = request("POST", "/api/articles", {article: {title: "Café déjà vu", description: "d", body: "b"}}, author)
assert_equal(201, status)
assert_equal("cafe-deja-vu", body.fetch("article").fetch("slug"))
status, body = request("POST", "/api/articles", {article: {title: "Ｆｕｌｌ Ｗｉｄｔｈ", description: "d", body: "b"}}, author)
assert_equal(201, status)
assert_equal("full-width", body.fetch("article").fetch("slug"))

assert_equal(409, request("POST", "/api/users", {user: {username: "author", email: "other@example.com", password: "password123"}}).first)
assert_equal(404, request("GET", "/api/articles/missing").first)
assert_equal(404, request("GET", "/api/profiles/nobody").first)
puts "RealWorld contract verified on Ruby #{RUBY_VERSION}p#{RUBY_PATCHLEVEL}"
