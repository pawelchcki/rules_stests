class ProfilesController < ApplicationController
  before_action :authenticate!, only: [:follow, :unfollow]

  def show
    user = find_profile
    render json: { profile: profile_json(user) } if user
  end

  def follow
    return unless @current_user
    user = find_profile
    return unless user
    Follow.find_or_create_by!(follower: @current_user, followed: user)
    render json: { profile: profile_json(user) }
  end

  def unfollow
    return unless @current_user
    user = find_profile
    return unless user
    Follow.where(follower: @current_user, followed: user).delete_all
    render json: { profile: profile_json(user) }
  end

  private

  def find_profile
    User.find_by(username: params[:username]) || (render_errors(:profile, "not found", :not_found); nil)
  end
end
