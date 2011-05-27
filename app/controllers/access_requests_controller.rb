class AccessRequestsController < ApplicationController
  before_filter :require_user
  before_filter :merge_user_id_with_note, :only => [:manager_approval, :resource_owner_approval]
  # GET /access_requests
  # GET /access_requests.xml
  def index
    if !params[:user_id].blank?
      @user = User.find(params[:user_id])
    else
      @user = current_user
    end
    @access_requests = AccessRequest.involved_user(params[:user_id]).by_created_at.with_extra_info.paginate(:per_page => 50, :page => params[:page])
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @access_requests }
    end
  end

  # GET /access_requests/1
  # GET /access_requests/1.xml
  def show
    @access_request = AccessRequest.find(params[:id])
    @request = @access_request.request
    # @access_request = @request.access_requests.find(params[:id])
    @note = @access_request.notes.new
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @access_request }
    end
  end

  # GET /access_requests/new
  # GET /access_requests/new.xml
  def new
    @access_request = AccessRequest.new
    @resource_groups = ResourceGroup.alphabetical.includes(:resources).all
    @subordinates = User.descendants_of(current_user).alphabetical_login.all if current_user.manager?
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @access_request }
    end
  end

  # GET /access_requests/new/permissions
  def permissions
    # TODO the two checks below should be moved to the model...    
    if params[:user_id].blank? || params[:user_id] == "For Myself"
      @user = current_user
    else
      @user = User.active.find(params[:user_id])
      if @user.blank? || !current_user.can_request_access_for?(@user)
        flash[:error] = "Oops! You are unable to request access for that user."
        redirect_to new_access_request_path and return
      end
    end
    
    if params[:resource_ids].blank?
      flash[:error] = "Oops! You forgot to select a resource. Please select at least one resource"
      redirect_to new_access_request_path and return
    end
    @request = Request.new(
      :reason => Request::REASONS[:standard],
      :created_by => current_user,
      :user => @user
    )    
    @access_requests = []
    @resources = Resource.find_all_by_id(params[:resource_ids])
    @resources.each do |resource|
      @access_request = @request.access_requests.new(
        :resource => resource,
        :request_action => AccessRequest::ACTIONS[:grant]
      )
      @access_requests << @access_request
    end
  end

  # POST /access_requests
  # POST /access_requests.xml
  # TODO combine this and rovoke_access since they both create access_requests
  # although, revoke_access can create access_requests for multiple resources which
  # could complicate things here instead of making them simpler
  def create
    @request = Request.create(params[:request].merge(:created_by => current_user))
    @access_requests = []
    params[:access_request].each_value do |value|
      access_request = @request.access_requests.build(
        :request_action => AccessRequest::ACTIONS[:grant],        
        :resource_id => value[:resource_id]
      )
      access_request.permission_requests.build(value["permission_requests_attributes"])
      access_request.notes.build(value['notes_attributes'])
      @access_requests << access_request
    end
    while @access_request = @access_requests.pop
      if @access_request.valid?
        if current_user.can_request_access_for?(@request.user)
          if @request.created_by_manager_for_subordinate?
            @access_request.manager = current_user
            @access_request.save
            @access_request.approve_all_permission_requests(@request.reason)
            flash[:notice] = "Resource owners have been notified about your access request."
          else
            @access_request.save
            flash[:notice] = "Access request has been sent to your manager."
          end
        # TODO FIXME this doesn't make sense here, the request has already been created
        # so it should be too late to not be allowed
        else
          @request.destroy
          flash[:error] = "You aren't allowed to do that."
          redirect_to dashboard_path and return
        end
      else
        @access_requests << @access_request
        render 'permissions'
        break
      end
    end
    @request.start!
    # TODO FIXME if users don't enter a note, the request won't transition to in_progress
    # and there will be 'pending' requests left around. This should prevent those,
    # but a much better solution would be to refactor the code above and corresponding
    # view code so that #pop loop above isn't necessary. "Look of disapproval" towards Roland!
    @request.reload # just to be safe here, even though I'm against excessive reloads
    @request.destroy if @request.pending?      
    redirect_to dashboard_path if @access_requests.empty?
  end

  # PUT /access_requests/1
  # PUT /access_requests/1.xml
  def update
    @access_request = AccessRequest.find(params[:id])
    respond_to do |format|
      if @access_request.update_attributes(params[:access_request])
        format.html { redirect_to(@access_request, :notice => 'Access request was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @access_request.errors, :status => :unprocessable_entity }
      end
    end
  end

  def manager_approval
    @access_request = AccessRequest.find(params[:id])
    # TODO move this into a before_filter
    unless current_user.descendants.include?(@access_request.request.user)
      flash[:error] = "You're not a manager of #{@access_request.request.user.full_name}."
      redirect_to @access_request and return
    end
    @access_request.attributes = {"manager_approval_attributes" => {}}.merge(params[:access_request])
    if @access_request.valid? && @access_request.save
      if @access_request.manager_denied_all?
        flash[:notice] = "All permissions have been denied."
        @access_request.deny!
      else
        if @access_request.resource.has_one_owner?
          @access_request.assign_to(@access_request.resource.users.first)
          flash[:notice] = "Request has been assigned to #{@access_request.resource_owner.full_name} for resource owner approval."
        else
          flash[:notice] = "Notifying resource owners"
          @access_request.send_to_resource_owners!
        end
      end
      redirect_to @access_request
    else
      @note = @access_request.notes.new
      @note.body = params[:access_request][:notes_attributes].first[:body] unless params[:access_request][:notes_attributes].first[:body] .blank?
      @access_request.reload
      @request = @access_request.request
      render 'show'
    end
  end

  # TODO see if this and manager_approval and be combined into a single approval method
  # FIXME approved_by_resource_owner not being set
  # need to implement similar manager_approval_attributes=(attributes)
  def resource_owner_approval
    @access_request = AccessRequest.find(params[:id])
    unless current_user.resources.include?(@access_request.resource) || current_user.descendants.detect {|desc| desc.resources.include?(@access_request.resource)}
      flash[:error] = "You're not a resource owner of #{@access_request.resource.long_name}."
      redirect_to :back and return
    end
    @access_request.attributes = {"resource_owner_approval_attributes" => {}}.merge(params[:access_request])
    if @access_request.valid? && @access_request.save
      if @access_request.resource_owner_denied_all?
        flash[:notice] = "Denying request."
        @access_request.deny!
      else
        flash[:notice] = "Request has been sent to help desk."
        @access_request.permission_requests.approved_by_resource_owner.each do |permission_request|
          permission_request.update_attribute(:permission_granted, true)
        end
        @access_request.send_to_help_desk!
      end
      redirect_to @access_request
    else
      @note = @access_request.notes.new
      @note.body = params[:access_request][:notes_attributes].first[:body] unless params[:access_request][:notes_attributes].first[:body] .blank?
      @access_request.reload
      @request = @access_request.request
      render 'show'
    end
  end

  def assign_request
    @access_request = AccessRequest.find(params[:id])
    if current_user == @access_request.user
      flash[:error] = "You can't assign access requests for you, to yourself."
      redirect_to dashboard_path and return
    end
    @access_request.assign_to(current_user)
    flash[:notice] = 'Access request has been assigned to you.'
    redirect_to @access_request
  end

  # /access_requests/revoke is where a manager chooses who do revoke access from
  def revoke
    @subordinates = User.active.descendants_of(current_user).alphabetical
  end

  # /access_requests/revoke/permissions is where a manager choosed which permissions
  # to revoke from the list of the users complete list of permissions
  def choose_permissions
    @user = User.find(params[:user_id])
    @access_request = @user.access_requests.new
    # @resources_with_permissions = Resource.user_has_access(@user).all
    @resource_groups = ResourceGroup.accessible_by(@user).alphabetical.all
  end

  # this is the action choose_permissions submits to
  # TODO FIXME if no permissions are selected, this raises a NoMethodError
  def revoke_access
    @user = User.find(params[:user_id])
    if params[:resources].blank?
      flash[:error] = "You need to select at least one permission to revoke."
      @access_request = @user.access_requests.new
      @resource_groups = ResourceGroup.accessible_by(@user).alphabetical.all
      @resources_with_permissions = Resource.user_has_access(@user).all
      render 'choose_permissions' and return
    end
    @user.generate_revoke_request!(
      :created_by => current_user,
      :resources => params[:resources]
    )

    flash[:notice] = "Request to revoke access for #{@user.full_name} has been sent to help desk."
    redirect_to dashboard_path
  end

  def complete
    @access_request = AccessRequest.find(params[:id])
    @access_request.complete!
    flash[:notice] = "Access request completed."
    redirect_to @access_request
  end

  def help_desk
    @requests = Request.with_extra_info.at_help_desk.by_importance.all
  end
  # DELETE /access_requests/1
  # DELETE /access_requests/1.xml
  def destroy
    @access_request = AccessRequest.find(params[:id])
    # @access_request.destroy
    flash[:error] = "Access requests should not be destroyed."
    respond_to do |format|
      format.html { redirect_to(access_requests_url) }
      format.xml  { head :ok }
    end
  end

  def unassign
    @access_request = AccessRequest.find(params[:id])
    @access_request.unassign!
    flash[:notice] = "Access Request has been unassigned"
    redirect_to access_request_path(@access_request)
  end

  def cancel
    @access_request = AccessRequest.find(params[:id])
    if @access_request.can_be_canceled_by?(current_user)
      @access_request.cancel!
      flash[:notice] = "Access Request has been canceled."
    else
      flash[:error] = "You can only cancel access requests that are for you."
    end
    redirect_to @access_request
  end
  
  protected

  # TODO put this in the note class if possible. at least out of here
  def merge_user_id_with_note
    params[:access_request][:notes_attributes].first[:user_id] = current_user.id #unless params[:access_request][:notes_attributes][:body].blank?
  end
end

