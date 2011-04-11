class Company < ActiveRecord::Base
  COMPANIES = {
    :example => {
      :name => 'Example',
      :email_domain => 'example.com'
    },
    :example2 => {
      :name => 'Example Second',
      :email_domain => 'example2.com'
    },
  }

  has_many :employees, :class_name => "User"

  define_index do
    indexes :name
    indexes email_domain
  end
  validates_presence_of :name, :email_domain
  validates_uniqueness_of :name, :email_domain
end

