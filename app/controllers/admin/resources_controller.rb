class Admin::ResourcesController < ApplicationController
  before_filter :require_admin
  # GET /resources
  # GET /resources.xml
  def index
    unless params[:resource_group_id].blank?
      @resource_group = ResourceGroup.find(params[:resource_group_id])
      @resources = @resource_group.resources.includes(:resource_group, :users).order("resource_groups.name, resources.name").paginate(:page => params[:page], :per_page => current_user.preferred_items_per_page)
    else
      # TODO FIXME for some reason the includes below stopped working when :permission_types is included
      # 'PGError: ERROR:  column permission_types.activated does not exist' but not sure why it thinks it should exist at this point
      @resources = Resource.includes(:resource_group, :users).order("resource_groups.name, resources.name").paginate(:page => params[:page], :per_page => current_user.preferred_items_per_page)
    end
    @resource_groups = ResourceGroup.order('name').all
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @resources }
    end
  end

  # GET /resources/1
  # GET /resources/1.xml
  def show
    @resource = Resource.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @resource }
    end
  end

  # GET /resources/new
  # GET /resources/new.xml
  def new
    @resource = Resource.new
    @resource_groups = ResourceGroup.alphabetical.all
    
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @resource }
    end
  end

  # GET /resources/1/edit
  def edit
    @resource = Resource.includes(:permission_types).find(params[:id])
    @users = User.active.alphabetical_login.has_some_access_to(@resource).paginate(:page => params[:page], :per_page => current_user.preferred_items_per_page)
    get_resource_info
    # @users = User.has_some_access_to(@resource).alphabetical.all
    flash[:error] = "Please assign an owner to this resource." if @resource.does_not_have_any_owners?
  end

  # POST /resources
  # POST /resources.xml
  def create
    @resource = Resource.new(params[:resource])

    respond_to do |format|
      if @resource.save
        format.html { redirect_to(edit_admin_resource_path(@resource), :notice => 'Resource was successfully created. Now select association permissions and resource owner.') }
        format.xml  { render :xml => @resource, :status => :created, :location => @resource }
      else
        @resource_groups = ResourceGroup.alphabetical.all
        format.html { render :action => "new" }
        format.xml  { render :xml => @resource.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /resources/1
  # PUT /resources/1.xml
  def update
    @resource = Resource.find(params[:id])
    respond_to do |format|
      if @resource.update_attributes(params[:resource])
        format.html { redirect_to(edit_admin_resource_path(@resource), :notice => 'Resource was successfully updated.') }
        format.xml  { head :ok }
      else
        get_resource_info
        format.html { render :action => "edit" }
        format.xml  { render :xml => @resource.errors, :status => :unprocessable_entity }
      end
    end
  end

    # POST /jobs/1/activate
  def activate
    @resource = Job.find(params[:resource_id])
    @resource.activate!
    flash[:notice] = "Resource successfully activated."
    respond_to do |format|
      format.html { redirect_to(edit_admin_resource_path(@resource)) }
      format.xml  { head :ok }
    end
  end
  
  # DELETE /resources/1
  # DELETE /resources/1.xml
  def destroy
    @resource = Resource.find(params[:id])
    @resource.deactivate!

    respond_to do |format|
      format.html { redirect_to(edit_admin_resource_url(@resource)) }
      format.xml  { head :ok }
    end
  end
  
  private
  
  def get_resource_info
    @resource_groups = ResourceGroup.alphabetical.all
    @permission_types = PermissionType.alphabetical.resource_group(@resource.resource_group).all
    # TODO find a way to do this in db
    # FIXME for some reason, the has_permission_type? call does not always
    # return true when it should so for some resources, admin/resources/3/edit at the
    # time of this writing, not all permission_types are floated to the front of the list
    owned_permissions = []
    @permission_types.each do |permission_type|
      if @resource.has_permission_type?(permission_type)
        owned_permissions << @permission_types.delete(permission_type)
      end
    end
    @permission_type_chunks = (owned_permissions + @permission_types).flatten
    @resource_owner_chunks = User.sort_by_last_name_first_name.all
    #TODO make this happen in one query, not 26
    @owners = {}
    ('a'..'z').each do |letter|
      @owners[letter.to_sym] = User.sort_by_last_name_first_name.where("lower(substr(last_name,1,1)) = ?", letter).all
      # logger.info "!!** #{letter}: #{@owners[letter.to_sym].inspect}"
    end
  end
end
