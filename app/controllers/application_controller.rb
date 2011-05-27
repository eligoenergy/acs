class ApplicationController < ActionController::Base
 # include ExceptionNotifier::Notifier
  layout 'application'
  protect_from_forgery
  helper_method :current_user_session, :current_user

  before_filter :get_current_user

  def default_url_options
    if Rails.env.production?
      {:host => App.email[:host], :protocol => App.email[:protocol]}
    else
      {}
    end    
  end
  
  def get_current_user
    current_user
  end

  def access_denied
    store_location
    flash[:error] = "You are not authorized to access that page"
    logger.info { "User attempted unathorized access to #{request.request_uri}" }
    logger.info { "session[:return_to] = #{session[:return_to]}" }
    redirect_to login_path # figure out best way to use :back
    false
  end

  def logged_in?
    !current_user.blank?
  end
  helper_method :logged_in?

  private

  def current_user_session
    return @current_user_session if defined?(@current_user_session)
    @current_user_session = UserSession.with_scope(:find_options => { :include => :roles }) do
      UserSession.find
    end
  end

  def current_user
    return @current_user if defined?(@current_user)
    @current_user = current_user_session && current_user_session.user
  end

  def require_user
    not_authenticated unless logged_in?
  end

  def require_no_user
    if current_user
      store_location
      flash[:notice] = "You must be logged out to access this page" unless request.fullpath == '/'
      redirect_to dashboard_path
      false
    end
  end

  # TODO these require_xxx methods need to be combined into one.
  def require_admin
    if logged_in?
      unless current_user.admin?
        not_authorized
      end
    else
      not_authenticated
    end
  end

  def require_hr
    if logged_in?
      unless current_user.hr?
        not_authorized
      end
    else
      not_authenticated
    end
  end
  
  def require_admin_or_hr
    if logged_in?
      unless current_user.is_admin_or_hr?
        not_authorized
      end
    else
      not_authenticated
    end    
  end

  def require_admin_or_hr_or_manager
    if logged_in?
      unless current_user.is_admin_or_hr? || current_user.manager?
        not_authorized
      end
    else
      not_authenticated
    end
  end

  # TODO find a more general name
  def require_can_view_termed_users
    if logged_in?
      unless current_user.is_admin_or_hr? || current_user.manager? || current_user.help_desk?
        not_authorized
      end
    else
      not_authenticated
    end
  end
  
  def not_authenticated
    store_going_to
    flash[:error] = "You must be logged in to do that!"
    redirect_to root_path
    return false
  end
  
  def not_authorized
    store_location
    flash[:error] = "You are not authorized to do that."
    redirect_to dashboard_path
    return false
  end
  
  def store_location
    session[:return_to] = request.referer
  end

  def store_going_to
    session[:going_to] = request.fullpath
  end

  def redirect_back_or_default(default)
    redirect_to(session[:going_to] || default)
    session[:going_to] = nil
  end
  
  def toggle_auto_refresh
    session[:auto_refresh] = session[:auto_refresh] ? false : true
  end
  
  def auto_refresh?
    session[:auto_refresh] ||= false
  end
  helper_method :auto_refresh?
  
  def collect_user_info
    @resource_groups = ResourceGroup.includes(:resources).accessible_by(@user).alphabetical.all
    @permissions = @user.permissions.all
    @all_resource_groups = ResourceGroup.includes(:resources => [:users]).alphabetical.all
    @resource_groups = ResourceGroup.includes(:resources).accessible_by(@user).alphabetical.all
    @resource_groups_with_ownerships = ResourceGroup.includes(:resources).with_resources_of(@user).alphabetical.all
    @managers = User.active.managers.alphabetical_login.all
    @employment_types = EmploymentType.alphabetical.all
    @descendants = User.active.descendants_of(@user).alphabetical_login.paginate(:page => params[:page], :per_page => 50) if @user.manager?    
  end
end

