class DashboardController < ApplicationController
  before_filter :require_user
  def index
    # TODO make all of these queries more efficient
    # TODO refactor @requests_in_progress
    @waiting_for_hr = User.waiting_for_hr.all if current_user.is_admin_or_hr?
    # @in_flight_users = User.created_by_me(current_user.id).with_incomplete_access_requests.all
    @requests_in_progress = Request.not_completed.for_user_and_descendants(current_user).with_extra_info.by_importance.paginate(:page => params[:page], :per_page => 40)
    @actionable_requests = Request.with_extra_info.not_completed.current_worker(current_user).by_importance.all    
    @requests_for_my_resources = Request.with_extra_info.for_resources_user_owns(current_user).with_access_requests_state('waiting_for_resource_owner_assignment').not_for_user(current_user).all 
    # TODO eliminates extra queries, but makes a huge query, need to do something about that...don't select *
    @termination_requests = Request.with_extra_info.not_completed.are_terminations.by_importance if current_user.help_desk? || current_user.hr? || current_user.admin?
    @help_desk_requests = Request.with_extra_info.unassigned_help_desk_requests.not_for_user(current_user).without_terminations.order('requests.created_at desc').all if current_user.help_desk?
    @recent_activity = current_user.requests.with_extra_info.completed.most_previous(5).all
    @permissions = current_user.permissions.all
    @resource_groups = ResourceGroup.accessible_by(current_user).alphabetical.all
  end
  
  def old_index
    # TODO make all of these queries more efficient
    # TODO refactor @requests_in_progress
    @waiting_for_hr = User.waiting_for_hr.all if current_user.is_admin_or_hr?
    @in_flight_users = User.created_by_me(current_user.id).with_incomplete_access_requests.all
    @requests_in_progress = AccessRequest.not_completed.for_user_and_descendants(current_user).with_extra_info.by_importance.paginate(:page => params[:page], :per_page => 40)
    @actionable_requests = AccessRequest.with_extra_info.not_completed.current_worker(current_user).by_importance.all    
    @requests_for_my_resources = AccessRequest.with_extra_info.for_resources_user_owns(current_user).with_state('waiting_for_resource_owner_assignment').not_for_user(current_user).all 
    # TODO eliminates extra queries, but makes a huge query, need to do something about that...don't select *
    @termination_requests = AccessRequest.with_extra_info.not_completed.are_terminations.by_importance if current_user.help_desk? || current_user.hr? || current_user.admin?
    @help_desk_requests = AccessRequest.with_extra_info.unassigned_help_desk_requests.not_for_user(current_user).without_terminations.order('created_at desc').all if current_user.help_desk?
    @recent_activity = current_user.access_requests.with_extra_info.completed.most_previous(5).all
    @permissions = current_user.permissions.all
    @resource_groups = ResourceGroup.accessible_by(current_user).alphabetical.all
  end
  def auto_refresh
    toggle_auto_refresh
    redirect_to dashboard_path
  end
end
