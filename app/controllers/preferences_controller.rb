class PreferencesController < ApplicationController

  def index
  end

  def show
  end
  
  def edit
    @preferences=current_user.preferences
  end
  
  def update
    @user = current_user
    @user.attributes = params[:preferences]
    @user.save!
    flash[:notice] = "Preferences updated"
    redirect_to preferences_path
  end
  
end
  
