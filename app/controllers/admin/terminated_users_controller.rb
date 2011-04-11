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
    if @user.rehire!
      @user.submitted_by = current_user
      Resource.for_job(@user.job).all.each do |resource|
        access_request = AccessRequest.create(
          :request_action => AccessRequest::ACTIONS[:grant],
          :reason => AccessRequest::REASONS[:rehire],
          :resource => resource,
          :permission_ids => resource.permissions.map{|perm| perm.id if perm.resource == resource }.compact,
          :user => @user,
          :created_by => current_user,
          :for_new_user => false
        )
        access_request.grant_all_permissions unless access_request.nil?
        access_request.send_to_help_desk!
      end
      @user.permissions.clear
      flash[:notice] = "Successfully rehired user and notified help desk"
    else
      flash[:error] = "Termination requests must be completed before the user is rehired"
    end 
    redirect_to @user 
   end
end
