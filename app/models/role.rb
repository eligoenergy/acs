class Role < ActiveRecord::Base
  ROLES = {
    :public => 'Public',
    :hr => 'HR',
    :help_desk => 'Help Desk',
    :admin => 'Admin',
    :auditor => 'Auditor'
  }
  # has_many :users
  has_and_belongs_to_many :users
#  acts_as_change_logger
  
  validates_presence_of :name
  validates_uniqueness_of :name
  validates_inclusion_of :name, :in => ROLES.values
end
