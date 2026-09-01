class CommentsController < ApplicationController
  before_action :authenticate!, only: [:create, :destroy]

  def index
    article = find_article
    return unless article
    comments = article.comments.includes(:user).order(:created_at, :id)
    render json: { comments: comments.map { |comment| comment_json(comment) } }
  end

  def create
    return unless @current_user
    article = find_article
    return unless article
    input = params.require(:comment).permit(:body)
    comment = article.comments.create!(input.merge(user: @current_user))
    render json: { comment: comment_json(comment) }, status: :created
  end

  def destroy
    return unless @current_user
    article = find_article
    return unless article
    comment = article.comments.find_by(id: params[:comment_id])
    return render_errors(:comment, "not found", :not_found) unless comment
    return unless require_owner!(comment, :comment)
    comment.destroy!
    head :no_content
  end
end
