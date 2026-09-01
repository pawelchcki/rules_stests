class ApplicationController < ActionController::API
  rescue_from ActionController::ParameterMissing do |error|
    render_errors(error.param, "is missing", :unprocessable_entity)
  end

  rescue_from ActiveRecord::RecordInvalid do |error|
    render_validation(error.record)
  end

  before_action :load_optional_user

  private

  def load_optional_user
    @current_user = user_from_token
  end

  def authenticate!
    return if @current_user
    message = request.headers["Authorization"].present? ? "is invalid" : "is missing"
    render_errors(:token, message, :unauthorized)
  end

  def user_from_token
    header = request.headers["Authorization"].to_s
    match = header.match(/\AToken\s+(.+)\z/)
    return unless match
    payload, = JWT.decode(match[1], jwt_secret, true, algorithm: "HS256", verify_expiration: true)
    User.find_by(id: payload["sub"])
  rescue JWT::DecodeError, ActiveRecord::RecordNotFound
    nil
  end

  def issue_token(user)
    JWT.encode({ sub: user.id.to_s, exp: 30.days.from_now.to_i, iat: Time.now.to_i }, jwt_secret, "HS256")
  end

  def jwt_secret
    ENV.fetch("JWT_SECRET", Rails.application.secret_key_base)
  end

  def render_errors(field, message, status)
    render json: { errors: { field.to_s => [message] } }, status: status
  end

  def render_validation(record, status: :unprocessable_entity)
    errors = record.errors.group_by_attribute.transform_values { |items| items.map(&:message) }
    render json: { errors: errors }, status: status
  end

  def profile_json(user)
    following = @current_user ? Follow.exists?(follower: @current_user, followed: user) : false
    { username: user.username, bio: user.bio, image: user.image, following: following }
  end

  def user_json(user)
    { email: user.email, token: issue_token(user), username: user.username, bio: user.bio, image: user.image }
  end

  def article_json(article, include_body: true)
    value = {
      slug: article.slug,
      title: article.title,
      description: article.description,
      tagList: article.tags.order(:id).pluck(:name),
      createdAt: article.created_at.iso8601(6),
      updatedAt: article.updated_at.iso8601(6),
      favorited: @current_user ? Favorite.exists?(article: article, user: @current_user) : false,
      favoritesCount: article.favorites.count,
      author: profile_json(article.user)
    }
    value[:body] = article.body if include_body
    value
  end

  def comment_json(comment)
    {
      id: comment.id,
      createdAt: comment.created_at.iso8601(6),
      updatedAt: comment.updated_at.iso8601(6),
      body: comment.body,
      author: profile_json(comment.user)
    }
  end

  def pagination
    limit = Integer(params.fetch(:limit, 20), exception: false) || 20
    offset = Integer(params.fetch(:offset, 0), exception: false) || 0
    [[limit, 0].max.clamp(0, 100), [offset, 0].max]
  end

  def find_article
    Article.includes(:user, :tags).find_by(slug: params[:slug]) ||
      (render_errors(:article, "not found", :not_found); nil)
  end

  def require_owner!(record, field)
    return true if record.user_id == @current_user.id
    render_errors(field, "forbidden", :forbidden)
    false
  end
end
