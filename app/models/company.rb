class Company < ActiveRecord::Base
  
  has_many :employees, :class_name => "User"

  define_index do
    indexes :name
    indexes email_domain
  end
  validates_presence_of :name, :email_domain
  validates_uniqueness_of :name, :email_domain
end

