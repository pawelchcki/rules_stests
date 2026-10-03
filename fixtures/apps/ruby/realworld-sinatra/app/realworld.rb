# encoding: utf-8
# Shared RealWorld implementation, kept compatible with Ruby 1.9.3.

require "bcrypt"
require "json"
require "jwt"
require "securerandom"
require "unicode_utils/nfkd"
require "sinatra/base"
require_relative "database"

module RealWorld
  # A request that cannot be answered: the JSON errors body and its status.
  class Failure < StandardError
    attr_reader :status, :errors

    def initialize(status, errors)
      super(errors.to_s)
      @status = status
      @errors = errors
    end
  end

  # The RealWorld API with the same observable behavior as the Rails fixture:
  # identical routes, status codes, and error messages.
  class App < Sinatra::Base
    set :show_exceptions, false
    set :raise_errors, false
    set :dump_errors, false
    set :host_authorization, {permitted_hosts: []}

    JWT_SECRET = ENV.fetch("JWT_SECRET", "rules-stests-development-only-secret-key-base")
    EMAIL = /\A[^\s@]+@[^\s@]+\.[^\s@]+\z/

    # Every value reaches SQLite as a bound variable, so the SQL text a tracer
    # records is the same on every run.
    USERS = DB[:users]
    ARTICLES = DB[:articles]
    TAGS = DB[:tags]
    ARTICLE_TAGS = DB[:article_tags]
    COMMENTS = DB[:comments]
    FAVORITES = DB[:favorites]
    FOLLOWS = DB[:follows]

    before do
      content_type "application/json; charset=utf-8"
      @current_user = user_from_token
    end

    error Failure do
      failure = env["sinatra.error"]
      status failure.status
      JSON.generate(errors: failure.errors)
    end

    ["/api", "/api/v1"].each do |prefix|
      post("#{prefix}/users") { register }
      post("#{prefix}/users/login") { login }
      get("#{prefix}/user") { current_user }
      put("#{prefix}/user") { update_user }

      get("#{prefix}/profiles/:username") { show_profile }
      post("#{prefix}/profiles/:username/follow") { follow(true) }
      delete("#{prefix}/profiles/:username/follow") { follow(false) }

      get("#{prefix}/articles/feed") { feed }
      get("#{prefix}/articles") { list_articles }
      post("#{prefix}/articles") { create_article }
      get("#{prefix}/articles/:slug") { show_article }
      put("#{prefix}/articles/:slug") { update_article }
      delete("#{prefix}/articles/:slug") { destroy_article }
      post("#{prefix}/articles/:slug/favorite") { favorite(true) }
      delete("#{prefix}/articles/:slug/favorite") { favorite(false) }
      get("#{prefix}/articles/:slug/comments") { list_comments }
      post("#{prefix}/articles/:slug/comments") { create_comment }
      delete("#{prefix}/articles/:slug/comments/:comment_id") { destroy_comment }
      get("#{prefix}/tags") { json(tags: rows(TAGS.select(:name).order(:id)).map { |tag| tag[:name] }) }
    end

    private

    # -- Users -----------------------------------------------------------------

    def register
      input = permit(required(:user), :username, :email, :password)
      user = normalize_identity(input)
      validate_user!(user, new_record: true)
      now = Time.now.utc
      id = insert(USERS, username: user[:username], email: user[:email],
        password_digest: BCrypt::Password.create(user[:password]).to_s, created_at: now, updated_at: now)
      status 201
      json(user: user_json(user_by_id(id)))
    rescue Sequel::UniqueConstraintViolation
      field = exists?(USERS.where(username: :$username), username: user[:username]) ? :username : :email
      fail!(409, field => ["has already been taken"])
    end

    def login
      input = permit(required(:user), :email, :password)
      fail!(422, email: ["can't be blank"]) if blank?(input[:email])
      fail!(422, password: ["can't be blank"]) if blank?(input[:password])
      user = row(USERS.where(email: :$email), email: input[:email].strip.downcase)
      unless user && BCrypt::Password.new(user[:password_digest]) == input[:password]
        fail!(401, credentials: ["invalid"])
      end
      json(user: user_json(user))
    end

    def current_user
      authenticate!
      json(user: user_json(@current_user))
    end

    def update_user
      authenticate!
      raw = required(:user)
      fail!(422, password: ["can't be blank"]) if raw.key?("password") && blank?(raw["password"])
      input = permit(raw, :username, :email, :password, :bio, :image)
      [:bio, :image].each { |key| input[key] = nil if input.key?(key) && blank?(input[key]) }
      user = @current_user.merge(normalize_identity(input))
      validate_user!(user, new_record: false, id: @current_user[:id])
      changes = select_keys(user, input.keys & [:username, :email, :bio, :image])
      changes[:password_digest] = BCrypt::Password.create(input[:password]).to_s if input.key?(:password)
      changes[:updated_at] = Time.now.utc
      update(USERS, @current_user[:id], changes)
      json(user: user_json(user_by_id(@current_user[:id])))
    rescue Sequel::UniqueConstraintViolation
      username_taken = exists?(USERS.exclude(id: :$id).where(username: :$username), id: @current_user[:id], username: user[:username])
      fail!(409, (username_taken ? :username : :email) => ["has already been taken"])
    end

    def normalize_identity(input)
      user = input.dup
      user[:username] = user[:username].strip if user[:username].is_a?(String)
      user[:email] = user[:email].strip.downcase if user[:email].is_a?(String)
      user
    end

    # Rails' validation order and messages; a taken identity answers 409.
    def validate_user!(user, options)
      new_record, id = options[:new_record], options[:id]
      errors = Hash.new { |hash, key| hash[key] = [] }
      errors[:password] << "can't be blank" if new_record && blank?(user[:password])
      errors[:username] << "can't be blank" if blank?(user[:username])
      errors[:email] << "can't be blank" if blank?(user[:email])
      others = id ? USERS.exclude(id: :$id) : USERS
      binds = id ? {id: id} : {}
      taken = false
      if !blank?(user[:username]) && exists?(others.where(username: :$username), binds.merge(username: user[:username]))
        errors[:username] << "has already been taken"
        taken = true
      end
      if !blank?(user[:email]) && exists?(others.where(email: :$email), binds.merge(email: user[:email]))
        errors[:email] << "has already been taken"
        taken = true
      end
      errors[:email] << "is invalid" if !blank?(user[:email]) && user[:email] !~ EMAIL
      password = user[:password]
      if password.is_a?(String) && (!password.empty? || new_record)
        errors[:password] << "is too short (minimum is 8 characters)" if password.length < 8
        errors[:password] << "is too long (maximum is 128 characters)" if password.length > 128
      end
      fail!(taken ? 409 : 422, errors) unless errors.empty?
    end

    def user_by_id(id)
      row(USERS.where(id: :$id), id: id)
    end

    def user_json(user)
      {email: user[:email], token: issue_token(user), username: user[:username], bio: user[:bio], image: user[:image]}
    end

    # -- Profiles --------------------------------------------------------------

    def show_profile
      json(profile: profile_json(find_profile))
    end

    def follow(value)
      authenticate!
      user = find_profile
      if value
        fail!(422, followed: ["cannot be self"]) if user[:id] == @current_user[:id]
        insert_ignore(FOLLOWS, follower_id: @current_user[:id], followed_id: user[:id])
      else
        delete(FOLLOWS.where(follower_id: :$follower, followed_id: :$followed), follower: @current_user[:id], followed: user[:id])
      end
      json(profile: profile_json(user))
    end

    def find_profile
      row(USERS.where(username: :$username), username: params[:username]) || fail!(404, profile: ["not found"])
    end

    def profile_json(user)
      following = @current_user &&
        exists?(FOLLOWS.where(follower_id: :$follower, followed_id: :$followed), follower: @current_user[:id], followed: user[:id])
      {username: user[:username], bio: user[:bio], image: user[:image], following: !!following}
    end

    # -- Articles --------------------------------------------------------------

    def list_articles
      scope, binds = ARTICLES, {}
      if present?(params[:tag])
        tagged = ARTICLE_TAGS.where(tag_id: TAGS.where(name: :$tag).select(:id)).select(:article_id)
        scope, binds = scope.where(id: tagged), binds.merge(tag: params[:tag])
      end
      if present?(params[:author])
        scope, binds = scope.where(user_id: USERS.where(username: :$author).select(:id)), binds.merge(author: params[:author])
      end
      if present?(params[:favorited])
        favorers = USERS.where(username: :$favorited).select(:id)
        scope = scope.where(id: FAVORITES.where(user_id: favorers).select(:article_id))
        binds = binds.merge(favorited: params[:favorited])
      end
      article_page(scope, binds)
    end

    def feed
      authenticate!
      followed = FOLLOWS.where(follower_id: :$follower).select(:followed_id)
      article_page(ARTICLES.where(user_id: followed), {follower: @current_user[:id]})
    end

    def article_page(scope, binds)
      limit, offset = pagination
      articles = limit.zero? ? [] : rows(scope.reverse(:created_at, :id).limit(limit).offset(offset), binds)
      json(articles: articles.map { |article| article_json(article, include_body: false) }, articlesCount: count(scope, binds))
    end

    def show_article
      json(article: article_json(find_article))
    end

    def create_article
      authenticate!
      raw = required(:article)
      input = permit(raw, :title, :description, :body)
      tags = tag_names(raw.key?("tagList") ? raw["tagList"] : [])
      validate_article!(input)
      article_id = DB.transaction do
        now = Time.now.utc
        id = insert(ARTICLES, user_id: @current_user[:id], slug: unique_slug(input[:title]), title: input[:title],
          description: input[:description], body: input[:body], created_at: now, updated_at: now)
        replace_tags(id, tags)
        id
      end
      status 201
      json(article: article_json(article_by_id(article_id)))
    end

    def update_article
      authenticate!
      article = find_article
      require_owner!(article, :article)
      raw = required(:article)
      input = permit(raw, :title, :description, :body)
      tags = raw.key?("tagList") ? tag_names(raw["tagList"]) : nil
      changes = select_keys(article, [:title, :description, :body]).merge(input)
      validate_article!(changes)
      DB.transaction do
        changes[:slug] = unique_slug(changes[:title]) if input.key?(:title) && input[:title] != article[:title]
        changes[:updated_at] = Time.now.utc
        update(ARTICLES, article[:id], changes)
        replace_tags(article[:id], tags) if tags
      end
      json(article: article_json(article_by_id(article[:id])))
    end

    def destroy_article
      authenticate!
      article = find_article
      require_owner!(article, :article)
      delete(ARTICLES.where(id: :$id), id: article[:id])
      no_content
    end

    def favorite(value)
      authenticate!
      article = find_article
      if value
        insert_ignore(FAVORITES, article_id: article[:id], user_id: @current_user[:id])
      else
        delete(FAVORITES.where(article_id: :$article, user_id: :$user), article: article[:id], user: @current_user[:id])
      end
      json(article: article_json(article))
    end

    def validate_article!(input)
      errors = {}
      [:title, :description, :body].each { |key| errors[key] = ["can't be blank"] if blank?(input[key]) }
      fail!(422, errors) unless errors.empty?
    end

    def tag_names(value)
      fail!(422, tagList: ["must be an array"]) unless value.is_a?(Array)
      value.map { |name| name.to_s.strip }.reject(&:empty?).uniq
    end

    def replace_tags(article_id, names)
      delete(ARTICLE_TAGS.where(article_id: :$article), article: article_id)
      names.each do |name|
        insert_ignore(TAGS, name: name)
        tag = row(TAGS.select(:id).where(name: :$name), name: name)
        insert(ARTICLE_TAGS, article_id: article_id, tag_id: tag[:id])
      end
    end

    # ActiveSupport's parameterize for the ASCII titles the scenarios use.
    def unique_slug(title)
      base = normalized_title(title).encode("ASCII", undef: :replace, invalid: :replace, replace: "")
        .downcase.gsub(/[^a-z0-9\-_]+/, "-").gsub(/-{2,}/, "-").gsub(/\A-|-\z/, "")
      base = "article" if base.empty?
      exists?(ARTICLES.where(slug: :$slug), slug: base) ? "#{base}-#{SecureRandom.hex(4)}" : base
    end

    def article_by_id(id)
      row(ARTICLES.where(id: :$id), id: id)
    end

    def find_article
      row(ARTICLES.where(slug: :$slug), slug: params[:slug]) || fail!(404, article: ["not found"])
    end

    def article_json(article, options = {})
      include_body = options.fetch(:include_body, true)
      tag_ids = ARTICLE_TAGS.where(article_id: :$article).select(:tag_id)
      favorited = @current_user &&
        exists?(FAVORITES.where(article_id: :$article, user_id: :$user), article: article[:id], user: @current_user[:id])
      value = {
        slug: article[:slug],
        title: article[:title],
        description: article[:description],
        tagList: rows(TAGS.select(:name).where(id: tag_ids).order(:id), article: article[:id]).map { |tag| tag[:name] },
        createdAt: article[:created_at].utc.iso8601(6),
        updatedAt: article[:updated_at].utc.iso8601(6),
        favorited: !!favorited,
        favoritesCount: count(FAVORITES.where(article_id: :$article), article: article[:id]),
        author: profile_json(user_by_id(article[:user_id]))
      }
      value[:body] = article[:body] if include_body
      value
    end

    # -- Comments --------------------------------------------------------------

    def list_comments
      article = find_article
      comments = rows(COMMENTS.where(article_id: :$article).order(:created_at, :id), article: article[:id])
      json(comments: comments.map { |comment| comment_json(comment) })
    end

    def create_comment
      authenticate!
      article = find_article
      input = permit(required(:comment), :body)
      fail!(422, body: ["can't be blank"]) if blank?(input[:body])
      now = Time.now.utc
      id = insert(COMMENTS, article_id: article[:id], user_id: @current_user[:id], body: input[:body], created_at: now, updated_at: now)
      status 201
      json(comment: comment_json(row(COMMENTS.where(id: :$id), id: id)))
    end

    def destroy_comment
      authenticate!
      article = find_article
      comment_id = integer_or_nil(params[:comment_id])
      comment = comment_id && row(COMMENTS.where(article_id: :$article, id: :$id), article: article[:id], id: comment_id)
      fail!(404, comment: ["not found"]) unless comment
      require_owner!(comment, :comment)
      delete(COMMENTS.where(id: :$id), id: comment[:id])
      no_content
    end

    def comment_json(comment)
      {
        id: comment[:id],
        createdAt: comment[:created_at].utc.iso8601(6),
        updatedAt: comment[:updated_at].utc.iso8601(6),
        body: comment[:body],
        author: profile_json(user_by_id(comment[:user_id]))
      }
    end

    # -- Queries ---------------------------------------------------------------

    def row(dataset, binds = {})
      dataset.call(:first, binds)
    end
    def rows(dataset, binds = {})
      dataset.call(:select, binds)
    end
    def exists?(dataset, binds = {})
      !dataset.select(Sequel.lit("1")).limit(1).call(:first, binds).nil?
    end
    def count(dataset, binds = {})
      dataset.select(Sequel.function(:count).*.as(:count)).call(:first, binds)[:count]
    end
    def insert(dataset, values = {})
      dataset.call(:insert, values, placeholders(values))
    end
    def delete(dataset, binds = {})
      dataset.call(:delete, binds)
    end

    def update(dataset, id, values)
      dataset.where(id: :$id).call(:update, values.merge(id: id), placeholders(values))
    end

    def select_keys(value, keys)
      keys.each_with_object({}) { |key, result| result[key] = value[key] }
    end

    def placeholders(values)
      values.each_with_object({}) { |(key, _), result| result[key] = :"$#{key}" }
    end

    def integer_or_nil(value)
      Integer(value)
    rescue ArgumentError, TypeError
      nil
    end

    def normalized_title(title)
      # Use one pinned Unicode implementation on every Ruby series.
      UnicodeUtils.nfkd(title.to_s)
    end

    def insert_ignore(dataset, values)
      insert(dataset, values)
    rescue Sequel::UniqueConstraintViolation
      nil
    end

    # -- Requests --------------------------------------------------------------

    def user_from_token
      match = env["HTTP_AUTHORIZATION"].to_s.match(/\AToken\s+(.+)\z/)
      return unless match
      payload, = JWT.decode(match[1], JWT_SECRET, true, algorithm: "HS256", verify_expiration: true)
      id = integer_or_nil(payload["sub"])
      id && user_by_id(id)
    rescue JWT::DecodeError
      nil
    end

    def issue_token(user)
      now = Time.now.to_i
      JWT.encode({sub: user[:id].to_s, exp: now + 30 * 24 * 3600, iat: now}, JWT_SECRET, "HS256")
    end

    def authenticate!
      return if @current_user
      fail!(401, token: [blank?(env["HTTP_AUTHORIZATION"]) ? "is missing" : "is invalid"])
    end

    def require_owner!(record, field)
      fail!(403, field => ["forbidden"]) unless record[:user_id] == @current_user[:id]
    end

    def body_json
      @body_json ||= begin
        text = request.body.read
        text.empty? ? {} : JSON.parse(text)
      rescue JSON::ParserError
        fail!(400, body: ["is invalid"])
      end
    end

    # Rails' params.require: a missing or empty object is 422 "is missing".
    def required(key)
      value = body_json.is_a?(Hash) ? body_json[key.to_s] : nil
      fail!(422, key => ["is missing"]) unless value.is_a?(Hash) && !value.empty?
      value
    end

    def permit(raw, *keys)
      keys.each_with_object({}) { |key, result| result[key] = raw[key.to_s] if raw.key?(key.to_s) }
    end

    def pagination
      limit = integer_or_nil(params.fetch("limit", 20)) || 20
      offset = integer_or_nil(params.fetch("offset", 0)) || 0
      [[[limit, 0].max, 100].min, [offset, 0].max]
    end

    def blank?(value)
      value.nil? || (value.is_a?(String) && value.strip.empty?)
    end
    def present?(value)
      !blank?(value)
    end
    def fail!(status, errors)
      raise(Failure.new(status, errors))
    end
    def json(value)
      JSON.generate(value)
    end

    def no_content
      status 204
      content_type nil
      ""
    end
  end
end
