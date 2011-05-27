class Admin::TerminatedUsersController < ApplicationController
  before_filter :require_can_view_termed_users
  before_filter :require_hr, :only => :rehire
    
  def index
    find_hash, kind = {:per_page => current_user.preferred_items_per_page, :page => params[:page]}, nil
    params.each_key{|k| kind = k if k =~ /_id$/ }
    if kind.blank?
      @users = User.terminated.with_extra_info.sort_by_last_name_first_name.paginate(find_hash)
    else
      @users = User.terminated.send("by_#{kind.gsub(/_id$/,'')}", params[kind]).with_extra_info.sort_by_last_name_first_name.paginate(find_hash)
    end
  end

  def rehire
    @user = User.find(params[:id])
    if @user.has_no_open_terminations
      @user.submitted_by = current_user
      @user.generate_future_employee_request!(
        :created_by => current_user,
        :hr => current_user,
        :reason => Request::REASONS[:rehire],
        :end_action => :rehire!
      )
      flash[:notice] = "Successfully rehired user and notified help desk"
    else
      flash[:error] = "Termination requests must be completed before the user is rehired"
    end 
    redirect_to @user 
   end
end
