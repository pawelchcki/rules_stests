class UsersController < ApplicationController
  before_action :authenticate!, only: [:show, :update]

  def create
    input = params.require(:user).permit(:username, :email, :password)
    user = User.new(input)
    if user.save
      render json: { user: user_json(user) }, status: :created
    elsif user.errors.of_kind?(:username, :taken) || user.errors.of_kind?(:email, :taken)
      render_validation(user, status: :conflict)
    else
      render_validation(user)
    end
  rescue ActiveRecord::RecordNotUnique
    field = User.exists?(username: input[:username]) ? :username : :email
    render_errors(field, "has already been taken", :conflict)
  end

  def login
    input = params.require(:user).permit(:email, :password)
    return render_errors(:email, "can't be blank", :unprocessable_entity) if input[:email].blank?
    return render_errors(:password, "can't be blank", :unprocessable_entity) if input[:password].blank?
    user = User.find_by(email: input[:email].strip.downcase)
    return render_errors(:credentials, "invalid", :unauthorized) unless user&.authenticate(input[:password])
    render json: { user: user_json(user) }
  end

  def show
    render json: { user: user_json(@current_user) } if @current_user
  end

  def update
    return unless @current_user
    raw = params.require(:user)
    return render_errors(:password, "can't be blank", :unprocessable_entity) if raw.key?(:password) && raw[:password].blank?
    input = raw.permit(:username, :email, :password, :bio, :image).to_h
    %w[bio image].each { |key| input[key] = nil if input.key?(key) && input[key].blank? }
    @current_user.assign_attributes(input)
    if @current_user.save
      render json: { user: user_json(@current_user) }
    elsif @current_user.errors.of_kind?(:username, :taken) || @current_user.errors.of_kind?(:email, :taken)
      render_validation(@current_user, status: :conflict)
    else
      render_validation(@current_user)
    end
  rescue ActiveRecord::RecordNotUnique
    field = User.where.not(id: @current_user.id).exists?(username: input["username"]) ? :username : :email
    render_errors(field, "has already been taken", :conflict)
  end
end
