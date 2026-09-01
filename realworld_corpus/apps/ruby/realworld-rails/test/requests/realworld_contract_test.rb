require "test_helper"

class RealworldContractTest < ActionDispatch::IntegrationTest
  def register(name = "alice")
    post "/api/v1/users", params: { user: { username: name, email: "#{name}@example.test", password: "password123" } }, as: :json
    assert_response :created
    response.parsed_body.dig("user", "token")
  end

  def auth(token)
    { "Authorization" => "Token #{token}" }
  end

  test "authentication rejects absent malformed and stale JWTs" do
    get "/api/v1/user"
    assert_response :unauthorized
    assert_equal ["is missing"], response.parsed_body.dig("errors", "token")

    get "/api/v1/user", headers: auth("broken")
    assert_response :unauthorized
    assert_equal ["is invalid"], response.parsed_body.dig("errors", "token")

    stale = JWT.encode({ sub: "1", exp: 1 }, Rails.application.secret_key_base, "HS256")
    get "/api/v1/user", headers: auth(stale)
    assert_response :unauthorized
  end

  test "duplicate identities use conflict while malformed identities use unprocessable entity" do
    register
    post "/api/v1/users", params: { user: { username: "alice", email: "other@example.test", password: "password123" } }, as: :json
    assert_response :conflict
    post "/api/v1/users", params: { user: { username: "", email: "empty@example.test", password: "password123" } }, as: :json
    assert_response :unprocessable_entity
  end

  test "nullable profile fields distinguish omission and normalize blank values" do
    token = register
    put "/api/v1/user", params: { user: { bio: "kept", image: "https://example.test/a.png" } }, headers: auth(token), as: :json
    assert_response :ok
    token = response.parsed_body.dig("user", "token")
    put "/api/v1/user", params: { user: { bio: "" } }, headers: auth(token), as: :json
    assert_nil response.parsed_body.dig("user", "bio")
    assert_equal "https://example.test/a.png", response.parsed_body.dig("user", "image")
    put "/api/v1/user", params: { user: { image: nil } }, headers: auth(token), as: :json
    assert_nil response.parsed_body.dig("user", "image")

    put "/api/v1/user", params: { user: { password: "" } }, headers: auth(token), as: :json
    assert_response :unprocessable_entity
    assert_equal ["can't be blank"], response.parsed_body.dig("errors", "password")

    put "/api/v1/user", params: { user: { password: nil } }, headers: auth(token), as: :json
    assert_response :unprocessable_entity
  end

  test "articles enforce ownership preserve omitted tags and combine filters" do
    alice = register("alice")
    bob = register("bob")
    post "/api/v1/articles", params: { article: { title: "Same title", description: "description", body: "body", tagList: ["ruby", "rails"] } }, headers: auth(alice), as: :json
    assert_response :created
    slug = response.parsed_body.dig("article", "slug")

    put "/api/v1/articles/#{slug}", params: { article: { body: "changed" } }, headers: auth(alice), as: :json
    assert_equal ["ruby", "rails"], response.parsed_body.dig("article", "tagList")
    put "/api/v1/articles/#{slug}", params: { article: { tagList: nil } }, headers: auth(alice), as: :json
    assert_response :unprocessable_entity
    put "/api/v1/articles/#{slug}", params: { article: { body: "stolen" } }, headers: auth(bob), as: :json
    assert_response :forbidden

    post "/api/v1/articles/#{slug}/favorite", headers: auth(bob)
    get "/api/v1/articles", params: { author: "alice", tag: "ruby", favorited: "bob", limit: 1, offset: 0 }
    assert_response :ok
    assert_equal 1, response.parsed_body["articlesCount"]
  end

  test "follow favorite and relationship writes are idempotent" do
    alice = register("alice")
    register("bob")
    2.times do
      post "/api/v1/profiles/bob/follow", headers: auth(alice)
      assert_response :ok
      assert response.parsed_body.dig("profile", "following")
    end
    2.times do
      delete "/api/v1/profiles/bob/follow", headers: auth(alice)
      assert_response :ok
      assert_not response.parsed_body.dig("profile", "following")
    end
  end
end
