class TagsController < ApplicationController
  def index
    render json: { tags: Tag.order(:id).pluck(:name) }
  end
end
