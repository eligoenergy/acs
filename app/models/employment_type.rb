class EmploymentType < ActiveRecord::Base
  TYPES = {
    :full_time => 'Full Time',
    :loa => 'LOA',
    :intern => 'Intern',
    :temp => 'Temp',
    :contractor => 'Contractor',
    :part_time => 'Part Time'
  }
  has_many :users

#  acts_as_change_logger

  validates_presence_of :name
  validates_uniqueness_of :name
  validates_inclusion_of :name, :in => TYPES.values

  scope :alphabetical, order("employment_types.name")
end

