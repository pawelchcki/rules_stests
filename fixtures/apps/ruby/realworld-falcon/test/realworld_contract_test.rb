# frozen_string_literal: true

# The build runs these against a fresh database before packaging the image.
require "minitest/autorun"
require "rack/test"
require_relative "../app/realworld"

class RealWorldContractTest < Minitest::Test
  include Rack::Test::Methods

  def app = RealWorld::App

  def call(method, path, body = nil, token: nil)
    header "Authorization", token ? "Token #{token}" : nil
    send(method, path, body && JSON.generate(body), "CONTENT_TYPE" => "application/json")
    [last_response.status, last_response.body.empty? ? nil : JSON.parse(last_response.body)]
  end

  def register(name)
    status, body = call(:post, "/api/users", {user: {username: name, email: "#{name}@example.com", password: "password123"}})
    assert_equal 201, status
    body.dig("user", "token")
  end

  def test_articles_comments_favorites_and_feed
    author = register("author")
    reader = register("reader")
    status, body = call(:post, "/api/articles", {article: {title: "Hello World", description: "d", body: "b", tagList: ["b", "a"]}}, token: author)
    assert_equal 201, status
    slug = body.dig("article", "slug")
    assert_equal "hello-world", slug
    assert_equal ["b", "a"], body.dig("article", "tagList")
    status, body = call(:post, "/api/articles", {article: {title: "Hello World", description: "d", body: "b"}}, token: author)
    assert_equal 201, status
    refute_equal slug, body.dig("article", "slug")
    assert_equal 403, call(:delete, "/api/articles/#{slug}", token: reader).first
    assert_equal({"errors" => {"article" => ["forbidden"]}}, call(:put, "/api/articles/#{slug}", {article: {title: "x"}}, token: reader).last)
    assert_equal 1, call(:post, "/api/articles/#{slug}/favorite", token: reader).last.dig("article", "favoritesCount")
    status, body = call(:post, "/api/articles/#{slug}/comments", {comment: {body: "nice"}}, token: reader)
    assert_equal 201, status
    assert_equal 403, call(:delete, "/api/articles/#{slug}/comments/#{body.dig("comment", "id")}", token: author).first
    assert_equal 204, call(:delete, "/api/articles/#{slug}/comments/#{body.dig("comment", "id")}", token: reader).first
    call(:post, "/api/profiles/author/follow", token: reader)
    status, body = call(:get, "/api/articles/feed?limit=1", token: reader)
    assert_equal [200, 2, 1], [status, body["articlesCount"], body["articles"].length]
    assert_equal 1, call(:get, "/api/articles?tag=a").last["articlesCount"]
    assert_equal 204, call(:delete, "/api/articles/#{slug}", token: author).first
    assert_equal ["b", "a"], call(:get, "/api/tags").last["tags"]
  end

  def test_error_contract
    assert_equal [401, {"errors" => {"token" => ["is missing"]}}], call(:get, "/api/user")
    assert_equal [401, {"errors" => {"token" => ["is invalid"]}}], call(:get, "/api/user", token: "junk")
    assert_equal [422, {"errors" => {"user" => ["is missing"]}}], call(:post, "/api/users", {})
    assert_equal ["can't be blank"], call(:post, "/api/users", {user: {email: "e@example.com", password: "password123"}}).last.dig("errors", "username")
    register("taken")
    status, body = call(:post, "/api/users", {user: {username: "taken", email: "other@example.com", password: "password123"}})
    assert_equal [409, ["has already been taken"]], [status, body.dig("errors", "username")]
    assert_equal [401, {"errors" => {"credentials" => ["invalid"]}}], call(:post, "/api/users/login", {user: {email: "taken@example.com", password: "wrong-password"}})
    assert_equal [404, {"errors" => {"profile" => ["not found"]}}], call(:get, "/api/profiles/nobody")
    assert_equal [404, {"errors" => {"article" => ["not found"]}}], call(:get, "/api/articles/missing")
  end
end
