class Job < ActiveRecord::Base
  include AASM
  
  belongs_to :department
  has_and_belongs_to_many :permissions, :uniq => true
  has_many :users

  acts_as_change_logger :track_templates => [:permissions]
  
  validates_presence_of :name
  validates_uniqueness_of :name, :scope => :department_id
  validates_presence_of :department_id 
  
  define_index do
    indexes :name, :sortable => true
    has department_id
  end
  
  scope :by_department, includes(:department).order("departments.name asc, jobs.name asc")
  scope :alphabetical, order("jobs.name asc")  
  scope :active, where(:current_state => 'active')
  
  aasm_column :current_state
  aasm_initial_state :active

  aasm_state :active
  aasm_state :deactivated

  aasm_event :deactivate do
    transitions :from => :active, :to => :deactivated
  end
  
  aasm_event :activate do
    transitions :from => :deactivated, :to => :active
  end
  
  def has_permission_in_resource_group?(resource_group)
    self.permissions.any? {|j| j.permission_type.resource_group == resource_group }
  end
  
  # take the passed in job, combine job templates, move all employees from all to self
  def combine_with(job)
    job.users.each do |user|
      user.update_attribute(:job_id, self.id)
    end
    self.permissions = (self.permissions + job.permissions).uniq
  end
end
