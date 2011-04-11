class Resource < ActiveRecord::Base
  has_many :permissions
  has_many :permission_types, :through => :permissions
  # has_many :users, :through => :permissions
  has_many :access_requests
  # this is the owners association
  # has_and_belongs_to_many :users, :uniq => true #, :after_remove => :record_association_remove, :after_add => :record_association_add
  has_and_belongs_to_many :users, :uniq => true #, :after_add => :do_a
  belongs_to :resource_group

  acts_as_change_logger
  
  validates_presence_of :name
  validates_uniqueness_of :name, :scope => :resource_group_id, :message => "already exists. Resource names must be unique per resource group"  
  
  scope :by_resource_group, includes(:resource_group).order("resource_groups.name asc, resources.name asc")
  scope :unassigned_access_requests, includes(:access_requests).where(["access_requests.current_state = ?", 'waiting_for_resource_owner_assignment'])
  scope :user_has_access, lambda {|user| includes([{:permissions => [:permission_type]}, :resource_group]).where(["resources.id in (#{Resource.users_resources(user)})"]).order('resource_groups.name asc, resources.name asc, permission_types.name asc')}
  scope :accessible_by, lambda {|user| includes([{:permissions => [:permission_type]}]).where(["resources.id in (#{Resource.users_resources(user)})"]).order('resources.name asc, permission_types.name asc')}
  scope :alphabetical, order("resources.name")
  scope :resource_group, lambda {|resource_group| where(:resource_group_id => resource_group.id) }
  scope :for_job, lambda {|job| includes(:permissions => :jobs).where('jobs.id = ?', job.id)}
  # scope :owner_count, lambda {|user| count(:conditions => ["resources_users.user_id = ?",user.id], :include => :users)} #"inner join resources_users on resources.id = resource_users.resource_id where resource_users.user_id = ?", user.id)}
  # scope :owned_by, lambda {|user| joins("resources_users on resources.id = resources_users.resource_id").where(["resources_users.user_id = ?", user.id])}

  define_index do
    indexes :name, :sortable => true
    #has resource_group_id
  end
    
  # TODO make sure this is correct
  def self.owned_by(user)
    "select id from resources
      inner join resources_users on resources.id = resources_users.resource_id
      where resources_users.user_id = #{user.id}
      group by resources.id"
  end
  
  def self.users_resources(user)
    "select distinct(resource_id) from permissions
      inner join permissions_users on permissions.id = permissions_users.permission_id
      where permissions_users.user_id = #{user.id}
      group by permissions.resource_id"
  end
  
  def has_permission_type?(permission_type)
    self.permission_types.include?(permission_type)
  end
  
  def has_permission?(permission)
    permissions.include?(permission)
  end
  
  def owned_by?(user)
    self.users.include?(user)
  end
  
  def has_owner?(users)
    users.each do |user|
      return true if self.users.include?(user)
    end
    false
  end
  
  def has_one_owner?
    self.users.count == 1
  end
  
  def has_unassigned_access_requests?
    self.access_requests.any? {|ar| ar.waiting_for_resource_owner_assignment? }
  end
  
  def unassigned_access_requests
    self.access_requests.where(:current_state => 'waiting_for_resource_owner_assignment')
  end
  
  def does_not_have_any_owners?
    self.users.blank?
  end
  
  def long_name
    "#{self.name} (#{self.resource_group.name})"
  end
  
  def group_name
    "#{self.resource_group.name} #{self.name}"
  end
  
end
