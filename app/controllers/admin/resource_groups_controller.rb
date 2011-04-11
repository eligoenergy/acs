class Admin::ResourceGroupsController < ApplicationController
  before_filter :require_admin
  # GET /resource_groups
  # GET /resource_groups.xml
  def index
    @resource_groups = ResourceGroup.all
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @resource_groups }
    end
  end

  # GET /resource_groups/1
  # GET /resource_groups/1.xml
  def show
    @resource_group = ResourceGroup.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @resource_group }
    end
  end

  # GET /resource_groups/new
  # GET /resource_groups/new.xml
  def new
    @resource_group = ResourceGroup.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @resource_group }
    end
  end

  # GET /resource_groups/1/edit
  def edit
    @resource_group = ResourceGroup.find(params[:id])
    @permission_types = @resource_group.permission_types.alphabetical.all
  end

  # POST /resource_groups
  # POST /resource_groups.xml
  def create
    @resource_group = ResourceGroup.new(params[:resource_group])

    respond_to do |format|
      if @resource_group.save
        format.html { redirect_to(admin_resources_path, :notice => 'Resource group was successfully created.') }
        format.xml  { render :xml => @resource_group, :status => :created, :location => @resource_group }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @resource_group.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /resource_groups/1
  # PUT /resource_groups/1.xml
  def update
    @resource_group = ResourceGroup.find(params[:id])

    respond_to do |format|
      if @resource_group.update_attributes(params[:resource_group])
        format.html { redirect_to(edit_admin_resource_group_path(@resource_group), :notice => 'Resource group was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @resource_group.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /resource_groups/1
  # DELETE /resource_groups/1.xml
  def destroy
    @resource_group = ResourceGroup.find(params[:id])
    @resource_group.destroy

    respond_to do |format|
      format.html { redirect_to(admin_resources_url) }
      format.xml  { head :ok }
    end
  end
end
