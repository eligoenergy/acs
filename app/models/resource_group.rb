class ResourceGroup < ActiveRecord::Base
  has_many :resources, :order => 'resources.name asc'
  has_many :active_resources, :order => 'resources.name asc', :conditions => {:current_state => 'active'}, :class_name => 'Resource'
  has_many :permission_types
  
#  acts_as_change_logger
  
  validates_presence_of :name
  validates_uniqueness_of :name
  
  define_index do
    indexes :name, :sortable => true
  end
  scope :alphabetical, order("resource_groups.name asc")
  scope :accessible_by, lambda { |user| includes(:resources => [ :permissions =>  [ :users ]]).where(['users.id = ?', user.id]) }
  scope :with_resources_of, lambda { |user| includes(:resources => [:users]).where('resources_users.user_id = ?', user.id) }
  scope :for_job, lambda {|job| includes(:resources => {:permissions => :jobs}).where('jobs.id = ?', job.id) }
end

