class PermissionType < ActiveRecord::Base
  has_many :permissions
  has_many :resources, :through => :permissions
  # has_many :users, :through => :permissions
  belongs_to :resource_group

  acts_as_change_logger
    
  validates_presence_of :name
  validates_uniqueness_of :name, :scope => :resource_group_id

  scope :alphabetical, order('permission_types.name')
  scope :resource_group, lambda {|resource_group| where(:resource_group_id => resource_group.id)}
  before_save :normalize_characters
  
  def normalize_characters
    # make lower case, substitute - for _, others?
    
  end
end
