require 'csv'
class Admin::UsersController < ApplicationController
  before_filter :require_admin_or_hr_or_manager
  before_filter :require_hr, :only => [:hr_confirm, :hr_veto]
  
  def index
    find_hash, kind = {:per_page => current_user.preferred_items_per_page, :page => params[:page]}, nil
    params.each_key{|k| kind = k if k =~ /_id$/ }
    if kind.blank?
      @users = User.active.with_extra_info.alphabetical_login.paginate(find_hash)
    else
      @users = User.active.send("by_#{kind.gsub(/_id$/,'')}", params[kind]).with_extra_info.alphabetical_login.paginate(find_hash)
    end
  end

  def new
    @user = User.new    
    @managers = get_managers
    @employment_types = EmploymentType.alphabetical.all
  end

  # /admin/users/new/permissions
  def permissions
    @user = User.new(params[:user])
    @permissions = @user.job.permissions.includes(:permission_type)
    @managers = get_managers
    @resource_groups = ResourceGroup.for_job(@user.job).alphabetical.includes({:resources => :permissions}).all
    @employment_types = EmploymentType.alphabetical.all
    if @user.job.permissions.blank?
      flash[:error] = "The selected job, #{@user.job.name} does not have a template. Please fix the template or select different job."
      render 'new'
    else
      # for some reason, if a job with zero permissions is selected and the above flash message is set,
      # when a valid job is selected, the flash doesn't go away
      flash.delete(:error) if flash[:error]
    end
  end

  def create
    @user = User.new(params[:user].merge(:submitted_by => current_user))
    if current_user.hr? && @user.save
      @user.generate_future_employee_request!(
        :created_by => @user.submitted_by,
        :hr => current_user,
        :manager => @user.submitted_by.descendants.include?(@user) ? @user.submitted_by : nil,
        :end_action => :activate!
      )
      # TODO wrap in an error catch block in case something unexpected happens on save
      flash[:notice] = "Successfully created new user and notified help desk"
      redirect_to @user
    elsif current_user.manager? && @user.save
      @user.verify_with_hr!
      flash[:notice] = "Successfully created new employee and notified HR for approval"
      redirect_to @user
    else
      @permissions = @user.job.permissions.includes(:permission_type)
      @managers = User.managers.alphabetical_login.all
      @resource_groups = ResourceGroup.alphabetical.includes({:resources => :permissions}).all
      @employment_types = EmploymentType.alphabetical.all
      render 'permissions'
    end
  end

  def update
    @user = User.find(params[:id])# makes our views "cleaner" and more consistent
    if current_user.is_admin_or_hr?
      if @user.update_attributes(params[:user])
        flash[:notice] = "Account updated!"
        redirect_to @user
      else
        collect_user_info        
        render 'users/show'
      end
    else
      flash[:error] = "You are not allowed to edit employees."
      redirect_to @user
    end
  end

  #/admin/users/new/csv
  def upload
    if params[:upload][:filetype].blank?
      flash[:error] = "Oops! It looks like you forgot to select the type of file you are importing. Please select a file and try again."
      redirect_to import_admin_users_path and return
    end
    if params[:upload][:file].blank?
      flash[:error] = "Oops! It looks like you forgot to attach a csv file. Please add a csv file and try again."
      redirect_to import_admin_users_path and return
    end
    if params[:note].blank?
      flash[:error] = "Oops! A note is required to import a csv file of employees. Please provide a note and try again."
      redirect_to import_admin_users_path and return
    end
    
    @file = []
    CSV.parse(params[:upload][:file].tempfile) do |row|
      @file << row unless row.blank?
    end
    @type = params[:upload][:filetype]
    @columns = App.csv[:types][@type]
    @validity = User.verify_csv_length(@file, @type)
    @results = User.import_from_csv(@validity, @file, @type, current_user, params[:note])
    render :controller => 'admin/users_controller', :action => "summary"
  end

  def summary
  end

  def import    
  end

  def terminate
    @user = User.find(params[:id])
    if (@user.active? && (current_user.hr? || @user.ancestors.include?(current_user)))
      unless @user.leaf?
        @user.direct_manager_of.each do |u|
          u.update_attribute(:manager, @user.manager)
        end
      end
      @user.access_requests.not_completed.each{ |access_request| access_request.cancel! }
      @user.generate_termination_request!(
        :created_by => current_user,
        :terminated_by => current_user,
        :end_action => current_user.hr? ? :terminate! : :suspend!
      )
    end
    if current_user.hr?
      @user.terminate! if @user.suspended?
      flash[:notice] = "Help desk has been notified of termination."
    elsif @user.ancestors.include?(current_user)
      flash[:notice] = "Termination request has been sent to hr for verification. Help desk has been notified of termination."
    end
    redirect_to user_path(@user)
  end

  def reactivate
    @user = User.find(params[:id])
    @user.reactivate!
    flash[:notice] = "Manager has been notified that their termination request has been denied."
    redirect_to user_path(@user)
  end
  
  def hr_confirm
    @user = User.find(params[:id])
    @request = @user.generate_future_employee_request!(
      :created_by => @user.submitted_by,
      :manager => @user.submitted_by,
      :hr => current_user,
      :end_action => :activate!
    )
    flash[:notice] = "#{@user.full_name} has been confirmed and their initial access requests have been generated."
    redirect_to @user
  end

  def hr_veto
    @user = User.find(params[:id])    
    @user.suspend!
    redirect_to @user
  end
  
  protected
  
  def get_managers    
    if current_user.hr?
      User.active.managers.alphabetical_login.all
    else
      User.active.descendants_of_with(current_user).alphabetical_login.all
    end
  end
end

