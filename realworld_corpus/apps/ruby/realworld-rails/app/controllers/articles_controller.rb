class ArticlesController < ApplicationController
  before_action :authenticate!, only: [:create, :update, :destroy, :favorite, :unfavorite, :feed]

  def index
    scope = filtered_articles(Article.all)
    count = scope.count
    limit, offset = pagination
    articles = scope.includes(:user, :tags, :favorites).order(created_at: :desc, id: :desc).limit(limit).offset(offset)
    render json: { articles: articles.map { |article| article_json(article, include_body: false) }, articlesCount: count }
  end

  def feed
    return unless @current_user
    scope = Article.where(user_id: @current_user.following.select(:id))
    count = scope.count
    limit, offset = pagination
    articles = scope.includes(:user, :tags, :favorites).order(created_at: :desc, id: :desc).limit(limit).offset(offset)
    render json: { articles: articles.map { |article| article_json(article, include_body: false) }, articlesCount: count }
  end

  def show
    article = find_article
    render json: { article: article_json(article) } if article
  end

  def create
    return unless @current_user
    raw = params.require(:article)
    input = raw.permit(:title, :description, :body)
    article = nil
    Article.transaction do
      article = @current_user.articles.new(input)
      article.slug = Article.unique_slug(input[:title])
      article.save!
      article.replace_tags!(raw.key?(:tagList) ? raw[:tagList] : [])
    end
    render json: { article: article_json(article.reload) }, status: :created
  rescue ActiveRecord::RecordNotUnique
    retry
  rescue ArgumentError
    render_errors(:tagList, "must be an array", :unprocessable_entity)
  end

  def update
    return unless @current_user
    article = find_article
    return unless article && require_owner!(article, :article)
    raw = params.require(:article)
    Article.transaction do
      article.assign_attributes(raw.permit(:title, :description, :body))
      article.slug = Article.unique_slug(article.title) if raw.key?(:title) && article.title_changed?
      article.save!
      article.replace_tags!(raw[:tagList]) if raw.key?(:tagList)
    end
    render json: { article: article_json(article.reload) }
  rescue ArgumentError
    render_errors(:tagList, "must be an array", :unprocessable_entity)
  end

  def destroy
    return unless @current_user
    article = find_article
    return unless article && require_owner!(article, :article)
    article.destroy!
    head :no_content
  end

  def favorite
    change_favorite(true)
  end

  def unfavorite
    change_favorite(false)
  end

  private

  def filtered_articles(scope)
    if params[:tag].present?
      scope = scope.where(id: ArticleTag.where(tag_id: Tag.where(name: params[:tag]).select(:id)).select(:article_id))
    end
    scope = scope.where(user_id: User.where(username: params[:author]).select(:id)) if params[:author].present?
    if params[:favorited].present?
      favorite_users = User.where(username: params[:favorited]).select(:id)
      scope = scope.where(id: Favorite.where(user_id: favorite_users).select(:article_id))
    end
    scope.distinct
  end

  def change_favorite(value)
    return unless @current_user
    article = find_article
    return unless article
    if value
      Favorite.find_or_create_by!(article: article, user: @current_user)
    else
      Favorite.where(article: article, user: @current_user).delete_all
    end
    render json: { article: article_json(article.reload) }
  end
end
