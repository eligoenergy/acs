class NotesController < ApplicationController
  before_filter :require_user
  def create
    @access_request = AccessRequest.find(params[:access_request_id])
    @note = @access_request.notes.new(params[:note])
    @note.user = current_user
    if @note.save
      flash[:notice] = "Successfully added comment"
    else
      flash[:error] = "Note was not saved. Please try again"
    end
    redirect_to @access_request
  end
end