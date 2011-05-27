class Request < ActiveRecord::Base
  include AASM
  
  REASONS = {
    :standard => 'standard',
    :revoke => 'revoke',
    :new_hire => 'new_hire',
    :transfer => 'transfer',
    :termination => 'termination',
    :rehire => 'rehire'
  }
  has_many :access_requests, :order => 'position'
  has_many :permission_requests, :through => :access_requests
  has_many :resources, :through => :access_requests
  has_many :notes
  belongs_to :user
  belongs_to :created_by, :class_name => 'User'
  
  accepts_nested_attributes_for :access_requests
  
  scope :not_completed, where('requests.current_state = ?', 'in_progress')
  scope :for_user_and_descendants, lambda { |user| where('requests.user_id in (?)', user.self_and_descendants.map{|u| u.id }) }
  scope :with_extra_info, includes(:user, :access_requests) # TODO this needs to be readded => [:permission_requests => {:permission => :permission_type}, :resource => :resource_group]])
  scope :by_importance, order('requests.reason desc, requests.created_at asc')
  scope :current_worker, lambda { |user| where('access_requests.current_worker_id = ?', user.id) }
  scope :for_resources_user_owns, lambda {|user| where(["access_requests.resource_id in (#{Resource.owned_by(user)})"]) }
  scope :with_access_requests_state, lambda { |aasm_state| where('access_requests.current_state = ?', aasm_state) }
  scope :for_user, lambda { |user_id| where(:user_id => user_id) }
  scope :not_for_user, lambda { |user| where('requests.user_id != ?', user.id) }
  scope :are_terminations, where(:reason => REASONS[:termination])
  scope :most_previous, lambda { |number| order('requests.completed_at desc').limit(number) }
  scope :unassigned_help_desk_requests, where('access_requests.current_state = ?', 'waiting_for_help_desk_assignment')
  scope :without_terminations, where('requests.reason != ?', REASONS[:termination])
  scope :at_help_desk, includes(:access_requests).where('access_requests.current_state in (?)', ['waiting_for_help_desk_assignment', 'waiting_for_help_desk'])
  scope :involved_user, lambda { |user_id| includes(:access_requests).where('requests.user_id = ? or requests.created_by_id = ? or access_requests.manager_id = ? or access_requests.help_desk_id = ? or access_requests.completed_by_id = ?', user_id, user_id, user_id, user_id, user_id)}
  scope :by_created_at, order('requests.created_at desc')
  
  aasm_column :current_state
  aasm_initial_state :pending

  aasm_state :pending
  aasm_state :in_progress
  aasm_state :completed
  
  aasm_event :start do
    transitions :from => :pending, :to => :in_progress
  end
  aasm_event :complete do
    transitions :from => :in_progress, :to => :completed
  end  
  
  def next(access_request)
    self.access_requests[access_request.position]
  end
  
  def previous(access_request)
    self.access_requests[access_request.position - 2]
  end
  
  def resource_ids=(ids)
    ids.each do |id|
      resource = Resource.find(id)
      self.access_requests.build(
        :resource => resource
      )
    end
  end
  
  def goes_directly_to_help_desk?
    ![REASONS[:standard]].include?(self.reason)
  end
  
  def reason?(reason)
    self.reason.to_sym == reason
  end
  
  # TODO find what uses this method and make it use reason?() method
  def for_termination?
    self.reason == REASONS[:termination]
  end
  
  def for?(user)
    self.user == user
  end
  
  def created_for_self?
    self.user == self.created_by
  end  
  
  def created_by_manager_for_subordinate?
    self.created_by.descendants.include?(self.user)
  end
  
  def order_access_requests_by_resource_name!
    self.access_requests.includes(:resource).order('resources.name').all.each_with_index do |access_request, index|
      access_request.update_attribute(:position, index + 1)
    end
  end
  
  # TODO make this update a column or find a way to make more efficient 
  def percent_complete
    @percent_complete ||= calculate_percent_complete
  end
  
  def calculate_percent_complete
    return 100 if self.completed?
    percentage_complete = 0.0
    if self.goes_directly_to_help_desk?
      total_steps = self.access_requests.size  
      self.access_requests.each do |access_request|
        percentage_complete += (1.0 / total_steps) if access_request.finished?
      end
    elsif self.created_by_manager_for_subordinate?
      # 2 is used here because for any given access request created by a manager
      # it must first go through a resource owner, and then help desk. 2 total
      # steps after initial creation
      total_steps = self.access_requests.size * 2
      self.access_requests.each do |access_request|
        percentage = case access_request.current_state
        when 'waiting_for_help_desk_assignment', 'waiting_for_help_desk'
          1.0 / total_steps
        when 'completed', 'denied', 'canceled'
          2.0 / total_steps
        end
        percentage_complete += percentage unless percentage.nil?
      end
    else
      # 3 is used here because for any given standard access request 
      # it must first go through a manager, then resource owner, and then help desk.
      # 3 total steps after initial creation
      total_steps = self.access_requests.size * 3
      self.access_requests.each do |access_request|
        percentage = case access_request.current_state
        when 'waiting_for_resource_owner_assignment', 'waiting_for_resource_owner'
          1.0 / total_steps
        when 'waiting_for_help_desk_assignment', 'waiting_for_help_desk'
          2.0 / total_steps
        when 'completed', 'denied', 'canceled'
          3.0 / total_steps
        end
        percentage_complete += percentage unless percentage.nil?
      end
    end
    (percentage_complete * 100).round
  end
end
