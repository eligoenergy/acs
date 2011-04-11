class Note < ActiveRecord::Base
  belongs_to :notable, :polymorphic => true, :dependent => :destroy
  belongs_to :user

  # notes don't need to be tracked as we do not expect them to change'
 # acts_as_change_logger

  validates_presence_of :body, :user_id

  before_create :set_created_at_step

  scope :pending, where(:created_at_step => 'pending')
  scope :waiting_for_manager, where(:created_at_step => 'waiting_for_manager')
  scope :waiting_for_resource_owner, where(:created_at_step => 'waiting_for_resource_owner')

  def set_created_at_step
    self.created_at_step = self.notable.current_state if self.notable.respond_to?(:current_state)
  end

end

