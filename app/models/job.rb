class Job < ActiveRecord::Base
  belongs_to :department
  has_and_belongs_to_many :permissions, :uniq => true #, :after_add => :do_this_stuff
  has_many :users
  
  # track_template_changes :permissions
  # acts_as_change_logger
  acts_as_change_logger :track_templates => [:permissions]
  
  validates_presence_of :name
  validates_uniqueness_of :name, :scope => :department_id
  validates_presence_of :department_id
  # before_save :wtf_before
  # after_save :wtf_after  
  
  define_index do
    indexes :name, :sortable => true
    has department_id
  end
  
  scope :by_department, includes(:department).order("departments.name asc, jobs.name asc")
  scope :alphabetical, order("jobs.name asc")
  
  def do_this_stuff(record)
    self.changed_permissions = [] if self.changed_permissions.nil?
    self.changed_permissions << record
  end
  
  def wtf_before
    logger.info { "\n\n********\n wtf_before: #{self.changed_permissions.inspect}\n********\n\n\n" }
  end

  def wtf_after
    logger.info { "\n\n********\n wtf_after: #{self.permissions.size}\n********\n\n\n" }
  end

  def has_permission_in_resource_group?(resource_group)
    self.permissions.any? {|j| j.permission_type.resource_group == resource_group }
  end
end
