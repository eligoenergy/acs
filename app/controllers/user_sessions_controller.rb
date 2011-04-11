class UserSessionsController < ApplicationController
  before_filter :require_no_user, :only => [:create, :new]
  before_filter :require_user, :only => :destroy

  def new
    @user_session = UserSession.new(params[:user_session])
  end

  def create
    # TODO this env? code doesn't look like it should belong he
    if Rails.env.development? || Rails.env.staging?
      users = params[:user_session][:login].split('-')
      session_user = User.find_by_login(users[1]) unless users[1].blank?
      unless users[1].blank?
        auth_user = User.find_by_login(users[0])
        params[:user_session][:login] = auth_user.login.to_s
      end
    end
    @user_session = UserSession.new(params[:user_session])

    if @user_session.save
      if session_user
        @user_session = UserSession.create(session_user)
      end
      redirect_back_or_default dashboard_path
    else
      flash[:error] = "Oops! You must have entered your username or password incorrectly."
      redirect_to login_path
    end
  end

  def destroy
    current_user_session.destroy
    flash[:notice] = "Logout successful!"
    redirect_to login_path
  end
end

