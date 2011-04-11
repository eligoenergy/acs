class SearchController < ApplicationController
  before_filter :require_user, :only => :users
  before_filter :require_admin, :only => :index
  
  def index
    @results = ThinkingSphinx.search params[:q], :match_mode => :any, :star => true, :populate => true, :order => "class_crc ASC, @relevance DESC"
    @results_grouping = @results.group_by(&:class)
  end
end