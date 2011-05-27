class Admin::JobsController < ApplicationController
  before_filter :require_admin
  # GET /jobs
  # GET /jobs.xml
  def index
    @jobs = Job.by_department.paginate(:page => params[:page], :per_page => current_user.preferred_items_per_page)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @jobs }
    end
  end

  # GET /jobs/1
  # GET /jobs/1.xml
  def show
    @job = Job.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @job }
    end
  end

  # GET /jobs/new
  # GET /jobs/new.xml
  def new
    @job = Job.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @job }
    end
  end

  # GET /jobs/1/edit
  def edit
    @job = Job.includes([:permissions, :users]).find(params[:id])
    @users = @job.users.active.with_extra_info.sort_by_last_name_first_name.paginate(:page => params[:page], :per_page => current_user.preferred_items_per_page)
    @resource_groups = ResourceGroup.alphabetical.includes(:resources => [:permissions, :permission_types]).all
  end

  # POST /jobs
  # POST /jobs.xml
  def create
    @job = Job.new(params[:job])

    respond_to do |format|
      if @job.save
        format.html { redirect_to(edit_admin_job_path(@job), :notice => 'Job was successfully created. Now select the appropriate permissions.') }
        format.xml  { render :xml => @job, :status => :created, :location => @job }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @job.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /jobs/1
  # PUT /jobs/1.xml
  def update
    @job = Job.find(params[:id])

    respond_to do |format|
      if @job.update_attributes(params[:job])
        format.html { redirect_to(edit_admin_job_path(@job), :notice => 'Job was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @job.errors, :status => :unprocessable_entity }
      end
    end
  end

  # POST /jobs/1/activate
  def activate
    @job = Job.find(params[:job_id])
    @job.activate!
    flash[:notice] = "Job successfully activated."
    respond_to do |format|
      format.html { redirect_to(edit_admin_job_path(@job)) }
      format.xml  { head :ok }
    end
  end
  # DELETE /jobs/1
  # DELETE /jobs/1.xml
  def destroy
    @job = Job.find(params[:id])
    @job.deactivate!
    flash[:notice] = "Job successfully deactivated."
    respond_to do |format|
      format.html { redirect_to(edit_admin_job_url(@job)) }
      format.xml  { head :ok }
    end
  end
end

