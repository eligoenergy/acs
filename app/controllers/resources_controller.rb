class ResourcesController < ApplicationController
  # GET /resources
  # GET /resources.xml
  def index
    unless params[:resource_group_id].blank?
      @resource_group = ResourceGroup.find(params[:resource_group_id])
      @resources = @resource_group.resources.includes(:resource_group, :permission_types, :users).order("resource_groups.name, resources.name").paginate(:page => params[:page], :per_page => current_user.preferred_items_per_page)
    else
      @resources = Resource.includes(:resource_group, :permission_types, :users).order("resource_groups.name, resources.name").paginate(:page => params[:page], :per_page => current_user.preferred_items_per_page)
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
end
