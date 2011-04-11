class UsersController < ApplicationController
  before_filter :require_user

  def index
    conditions = User.active
    conditions = conditions.coworker_number(params[:coworker_number]) unless params[:coworker_number].blank?
    conditions = conditions.first_name(params[:first_name]) unless params[:first_name].blank?
    conditions = conditions.last_name(params[:last_name]) unless params[:last_name].blank?
    conditions = conditions.ldap_name(params[:ldap_name]) unless params[:ldap_name].blank?
    # conditions = conditions.start_date(params[:start_date]) unless params[:start_date].blank?
    conditions = conditions.by_department(params[:department_id]) unless params[:department_id].blank?
    conditions = conditions.descendants_of(User.find(params[:manager_id])) unless params[:manager_id].blank?
    conditions = conditions.by_location(params[:location_id]) unless params[:location_id].blank?
    conditions = conditions.job(params[:job_id]) unless params[:job_id].blank?
    
    @users = conditions.order('login asc').includes({:job => {:department => :location}}, :manager).paginate(:page => params[:page], :per_page => current_user.preferred_items_per_page)
    @managers = User.managers.alphabetical_login.all
  end
  
  def show
    @user = User.includes(:permissions, :resources).find(params[:id])
    collect_user_info
  end
end
