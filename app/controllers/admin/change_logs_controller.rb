class Admin::ChangeLogsController < ApplicationController
  before_filter :require_admin
  
  def index
    if params[:job_id]
      where = {:item_type => 'Job', :item_id => params[:job_id].to_i}
      @changes = ChangeLog.where(where).order("created_at desc").paginate(:page => params[:page], :per_page => current_user.preferred_items_per_page)
    else
      @changes = ChangeLog.order("created_at desc").paginate(:page => params[:page], :per_page => current_user.preferred_items_per_page)
    end
  end

end
