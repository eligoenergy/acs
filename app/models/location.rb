class Location < ActiveRecord::Base
  has_many :departments
  
  acts_as_change_logger
  
  validates_presence_of :name
  validates_uniqueness_of :name
  
  define_index do
    indexes :name, :sortable => true
  end
  
  scope :alphabetical, order("locations.name asc")
  
  # TODO better way of doing this? 
  def employees
    User.joins(:job => [ :department => [ :location]]).where(['locations.id = ?', self.id]).all
  end
end
