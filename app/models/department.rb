class Department < ActiveRecord::Base
  belongs_to :location
  has_many :jobs, :order => 'jobs.name asc'
  has_many :users, :through => :jobs
  has_many :managers, :class_name => 'User',
    :finder_sql => "select * from users u
      join jobs j on u.job_id = j.id
      join departments d on j.department_id = d.id
      where d.id = 1 and
      u.manager_flag = true"

  acts_as_change_logger

#  before_save :titleize_name

  validates_presence_of :name
  validates_uniqueness_of :name, :scope => :location_id
  validates_presence_of :location_id
  
  define_index do
    indexes :name, :sortable => true
    has location_id
  end
  
  scope :alphabetical, order("name asc")
  scope :by_location, lambda { |location_id| where(:location_id => location_id) }

  #TODO make this a has_many assocition
  def dept_managers
    results = []
    self.jobs.each do |job|
      results << job.users.where(:manager_flag => true)
    end
    results.flatten
  end
end
