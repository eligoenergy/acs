class Admin::PermissionTypesController < ApplicationController
  # GET /admin/permission_types
  # GET /admin/permission_types.xml
  before_filter :get_resource_group
  	
  def index
    @permission_types = PermissionType.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @permission_types }
    end
  end

  # GET /admin/permission_types/1
  # GET /admin/permission_types/1.xml
  def show
    @permission_type = PermissionType.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @permission_type }
    end
  end

  # GET /admin/permission_types/new
  # GET /admin/permission_types/new.xml
  def new
    @permission_type = PermissionType.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @permission_type }
    end
  end

  # GET /admin/permission_types/1/edit
  def edit
    @permission_type = PermissionType.find(params[:id])
  end

  # POST /admin/permission_types
  # POST /admin/permission_types.xml
  def create
    @permission_type = @resource_group.permission_types.new(params[:permission_type])

    respond_to do |format|
      if @permission_type.save
        format.html { redirect_to(edit_admin_resource_group_path(@resource_group), :notice => 'Permission type was successfully created.') }
        format.xml  { render :xml => @permission_type, :status => :created, :location => @permission_type }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @permission_type.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /admin/permission_types/1
  # PUT /admin/permission_types/1.xml
  def update
    @permission_type = PermissionType.find(params[:id])

    respond_to do |format|
      if @permission_type.update_attributes(params[:permission_type])
        format.html { redirect_to(@permission_type, :notice => 'Permission type was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @permission_type.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /admin/permission_types/1
  # DELETE /admin/permission_types/1.xml
  def destroy
    @permission_type = PermissionType.find(params[:id])
    @permission_type.destroy

    respond_to do |format|
      format.html { redirect_to(permission_types_url) }
      format.xml  { head :ok }
    end
  end
  
  private

  def get_resource_group
  	  @resource_group = ResourceGroup.find(params[:resource_group_id])
  end
end
