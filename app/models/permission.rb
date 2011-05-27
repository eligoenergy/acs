class Permission < ActiveRecord::Base
  belongs_to :permission_type
  belongs_to :resource
  has_and_belongs_to_many :jobs, :uniq => true
  has_and_belongs_to_many :users, :uniq => true
  
  # acts_as_change_logger
  
  validates_uniqueness_of :permission_type_id, :scope => :resource_id
  # TODO this is here, but doesn't seem to actually be doing anything
  # this functionality was also wrapped up in the acs/permission_keeper module also
  # make sure it doesn't break anything and then remove it
  before_destroy :validate_not_active
  
  scope :of, lambda { |user| joins(:users).where(['users.id = ?', user.id])}
  scope :for_resource, lambda { |resource| where(:resource_id => resource.id) }
  
  def validate_not_active
    self.resource.errors[:base] << "You can't remove that"
  end
end
