class DepartmentsController < ApplicationController
  # GET /departments
  # GET /departments.xml
  def index
    if !params[:location_id].blank?
      @departments = Department.by_location(params[:location_id]).paginate(:per_page => current_user.preferred_items_per_page, :page => params[:page])
    # elsif !params[:department_id].blank?
      # @users = User.by_department(params[:department_id]).sort_by_last_name_first_name.paginate(:per_page => current_user.preferred_items_per_page, :page => params[:page])
    else
      @departments = Department.paginate(:per_page => current_user.preferred_items_per_page, :page => params[:page])
    end

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @departments }
    end
  end

  # GET /departments/1
  # GET /departments/1.xml
  def show
    @department = Department.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @department }
    end
  end
end
