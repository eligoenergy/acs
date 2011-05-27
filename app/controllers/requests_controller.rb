class RequestsController < ApplicationController
  before_filter :require_user
  
  def index
    
    if !params[:user_id].blank?
      @user = User.find(params[:user_id])
      @requests = Request.involved_user(@user.id).by_created_at.with_extra_info.paginate(:per_page => 50, :page => params[:page])
    else
      @requests = Request.by_created_at.with_extra_info.paginate(:per_page => 50, :page => params[:page])
    end
    
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @access_requests }
    end
  end
  
  def show
    @request = Request.find(params[:id])
  end
end