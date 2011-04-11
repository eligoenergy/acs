require 'access_requests/state_machine_helper'
class AccessRequest < ActiveRecord::Base
  include AASM
  include AccessRequests::StateMachineHelper
  include AccessRequests::StatusHelper
  extend AccessRequests::Reminders
  
  ACTIONS = {
    :grant => 'grant',
    :revoke => 'revoke'
  }
  # FIXME there shouldn't be a revoke/revoke action/reason. It should
  # be revoke/standard but it doesn't seem to work right atm
  REASONS = {
    :standard => 'standard',
    :revoke => 'revoke',
    :new_hire => 'new_hire',
    :transfer => 'transfer',
    :termination => 'termination',
    :rehire => 'rehire'
  }

  belongs_to :resource
  belongs_to :user
  belongs_to :created_by, :class_name => 'User'
  belongs_to :current_worker, :class_name => 'User'
  belongs_to :manager, :class_name => 'User'
  belongs_to :resource_owner, :class_name => 'User'
  belongs_to :help_desk, :class_name => 'User'
  belongs_to :hr, :class_name => 'User'
  belongs_to :completed_by, :class_name => 'User'
  has_many :permission_requests, :dependent => :destroy
  has_many :permissions, :through => :permission_requests
  has_many :notes, :as => :notable, :dependent => :destroy, :order => 'notes.created_at asc'

  acts_as_change_logger :ignore => [:created_by_id, :historical, :request_action, :user_id, :completed_at, :created_at, :updated_at, :manager_id, :resource_owner_id, :for_new_user]

  accepts_nested_attributes_for :permission_requests #, :reject_if => Proc.new { |permission_request| }
  accepts_nested_attributes_for :notes #, :reject_if => Proc.new { |note| note[:body].blank? }

  attr_accessor :approved_by, :permission_ids, :current_user, :manager_approval_attributes, :validate_manager_approval, :resource_owner_approval_attributes, :validate_resource_owner_approval, :valid_note_required, :created_by_import, :created_by_transfer

  validates_with AccessRequests::Validator

  scope :unassigned_requests, where(:current_state => 'waiting_for_resource_owner_assignment')
  scope :not_completed, where('access_requests.current_state not in (?) and completed_at is null', ['completed','denied', 'canceled'])
  scope :for_hr, where(:current_state => ['waiting_for_hr_assignment', 'waiting_for_hr']).order('created_at desc')
  scope :for_user_and_descendants, lambda { |user| where('user_id in (?)', user.self_and_descendants.map{|u| u.id }) }
  scope :current_worker, lambda { |user| where(:current_worker_id => user.id) }
  scope :unassigned_help_desk_requests, where(:current_state => 'waiting_for_help_desk_assignment')
  scope :at_help_desk, where(:current_state => ['waiting_for_help_desk_assignment', 'waiting_for_help_desk'])
  scope :completed, where('access_requests.current_state in (?)', ['completed', 'denied', 'canceled'])
  scope :most_previous, lambda { |number| order('completed_at desc').limit(number) }
  scope :for_descendants, lambda { |user| where(['user_id in (:descendants) or current_worker_id in (:descendants) or created_by_id in (:descendants)'], :descendants => user.descendants.map{|u| u.id}) }
  scope :for_user, lambda { |user_id| where(:user_id => user_id) }
  scope :not_for_user, lambda { |user| where('access_requests.user_id != ?', user.id) }
  scope :by_created_at, order('created_at desc')
  scope :with_state, lambda { |aasm_state| where('access_requests.current_state = ?', aasm_state) }
  scope :for_resources_user_owns, lambda {|user| includes(:resource).where(["access_requests.resource_id in (#{Resource.owned_by(user)})"]) }
  scope :but_not, lambda {|access_request| where('access_requests.id != ?', access_request.id) unless access_request.id.nil? }
  scope :historical, where(:historical => true)
  scope :are_terminations, where(:reason => REASONS[:termination])
  scope :without_terminations, where('access_requests.reason != ?', REASONS[:termination])
  scope :by_importance, order('access_requests.reason desc, access_requests.request_action desc, access_requests.created_at asc')
  scope :with_extra_info, includes(:user, {:permission_requests => {:permission => :permission_type}}, {:resource => :resource_group})
  scope :to_revoke, where(:request_action => ACTIONS[:revoke])
  scope :to_grant, where(:request_action => ACTIONS[:grant])
  scope :involved_user, lambda { |user_id| where('access_requests.user_id = ? or access_requests.created_by_id = ? or access_requests.manager_id = ? or access_requests.help_desk_id = ? or access_requests.completed_by_id = ?', user_id, user_id, user_id, user_id, user_id)}
  
  aasm_column :current_state
  aasm_initial_state :pending

  aasm_state :pending

  aasm_state :waiting_for_manager,
    :enter => :assign_to_manager,
    :exit => :unassign_current_worker

  aasm_state :waiting_for_resource_owner,
    :exit => :unassign_current_worker
  aasm_state :waiting_for_help_desk

  aasm_state :waiting_for_resource_owner_assignment
  aasm_state :waiting_for_help_desk_assignment,
    :enter => :unassign_current_worker

  aasm_state :canceled
  aasm_state :completed,
    :enter => :modify_permissions
  aasm_state :denied

  aasm_event :send_to_manager do
    transitions(
      :from => :pending,
      :to => :waiting_for_manager,
      :guard => :created_for_self?
    )
  end
  aasm_event :send_to_hr do
    transitions(
      :from => :pending,
      :to => :waiting_for_hr_assignment,
      :guard => :created_by_manager_for_new_employee?
    )
    transitions(
      :from => :pending,
      :to => :waiting_for_hr_assignment,
      :guard => :created_by_manager_to_terminate_current_user
	)
  end  
  aasm_event :send_to_resource_owners do
    transitions(
      :from => :waiting_for_manager,
      :to => :waiting_for_resource_owner_assignment,
      :guard => :approved_by_manager?
    )
    transitions(
      :from => :pending,
      :to => :waiting_for_resource_owner_assignment,
      :guard => :by_manager_for_subordinate?
    )
  end
  aasm_event :send_to_help_desk do
    transitions(
      :from => :waiting_for_resource_owner,
      :to => :waiting_for_help_desk_assignment
    )
    transitions(
      :from => :pending,
      :to => :waiting_for_help_desk_assignment,
      :guard => :can_go_directly_to_help_desk?
    )    
  end
  aasm_event :send_revoke_request_to_help_desk do
    transitions(
      :from => :pending,
      :to => :waiting_for_help_desk_assignment
    )
  end
  aasm_event :assign_to_resource_owner do
    transitions(
      :from => :waiting_for_resource_owner_assignment,
      :to => :waiting_for_resource_owner
    )
    transitions(
    :from => :waiting_for_manager,
    :to => :waiting_for_resource_owner,
    :guard => :resource_has_one_owner?
    )
  end
  aasm_event :assign_to_help_desk do
    transitions(
      :from => :waiting_for_help_desk_assignment,
      :to => :waiting_for_help_desk
    )
  end
  aasm_event :unassign do
    transitions(
      :from => :waiting_for_help_desk,
      :to => :waiting_for_help_desk_assignment
    )
  end
  aasm_event :cancel do
    transitions(
      :from => [:pending, :waiting_for_manager, :waiting_for_hr, :waiting_for_hr_assignment, :waiting_for_resource_owner,
        :waiting_for_help_desk, :waiting_for_resource_owner_assignment, :waiting_for_help_desk_assignment ],
      :to => :canceled
    )
  end
  aasm_event :complete do
    transitions(
      :from => :waiting_for_help_desk,
      :to => :completed
    )
  end
  aasm_event :deny do
    transitions(
      :from => [:waiting_for_manager, :waiting_for_hr, :waiting_for_resource_owner],
      :to => :denied
    )
  end
  
  def reason?(reason)
    self.reason.to_sym == reason
  end
  
  def permission_ids=(ids)
    ids.each do |id|
      self.permission_requests.build(:permission_id => id)
    end
  end

  def manager_approval_attributes=(attributes)
    self.permission_requests.each do |permission_request|
      approved = attributes.delete(permission_request.id.to_s)
      permission_request.approval(approved.nil? ? nil : approved[:approved])
    end
    self.validate_manager_approval = true
  end

  def need_to_validate_manager_approval?
    self.validate_manager_approval ||= false
  end

  def resource_owner_approval_attributes=(attributes)
    self.permission_requests.approved_by_manager.each do |permission_request|
      approved = attributes.delete(permission_request.id.to_s)
      permission_request.approval(approved.nil? ? nil : approved[:approved])
    end
    self.validate_resource_owner_approval = true
  end

  def need_to_validate_resource_owner_approval?
    self.validate_resource_owner_approval ||= false
  end

  def approve_all_permission_requests
    self.permission_requests.each do |permission_request|
      permission_request.approval(true)
    end
  end

  def grant_all_permissions
    self.permission_requests.each do |permission_request|
      permission_request.update_attribute(:permission_granted, true)
    end
  end

  def final_approved_permissions
    if self.for_termination?
      self.permission_requests.all
    else
      self.resource_owner_approved_permissions
    end
  end

  def manager_denied_all?
    self.permission_requests.denied_by_manager.size == self.permission_requests.size
  end

  def resource_owner_denied_all?
    self.permission_requests.approved_by_manager.size > 0 && self.permission_requests.denied_by_resource_owner.size == self.permission_requests.approved_by_manager.size
    # self.permission_requests.approved_by_manager.all? { |pr| pr.approved_by_resource_owner == false }
  end

  def denied_by_manager_or_resource_owner?
    manager_denied_all? || resource_owner_denied_all?
  end
  
  def canceled_before_manager_review?
    permission_requests.all? {|permission_request| permission_request.approved_by_manager_at.nil? }
  end
  
  def canceled_before_resource_owner_review?
    manager_approved_permissions.blank? || manager_approved_permissions.any? {|permission_request| permission_request.approved_by_resource_owner_at.nil? }
  end
  
  def finished?
    ['completed', 'denied', 'canceled'].include?(self.current_state)
  end

  def notes_are_disabled?
    finished? && self.completed_at && self.completed_at < Time.now - 15.minutes
  end
  
  def at_help_desk?
    ['waiting_for_help_desk_assignment', 'waiting_for_help_desk'].include?(self.current_state)
  end

  def for_termination?
    self.reason == AccessRequest::REASONS[:termination]
  end

  def unassign_current_worker
    self.current_worker = nil
  end

  # TODO what is the ruby way to do this? :& or something like that. find_by_sql? in permission model?
  def permission_types
    types = []
    self.permission_requests.includes(:permission => :permission_type).each do |pr|
      types << pr.permission.permission_type.name
    end
    types
  end

  def manager_approved_permissions
    self.permission_requests.approved_by_manager.all
  end

  def manager_denied_permissions
    self.permission_requests.denied_by_manager.all
  end

  def resource_owner_approved_permissions
    self.permission_requests.approved_by_resource_owner.all
  end

  def resource_owner_denied_permissions
    self.permission_requests.denied_by_resource_owner.all
  end

  def by_manager_for_subordinate?
    self.created_by.descendants.include?(self.user)
  end

  def assign_to_manager
    self.manager = self.user.manager
    self.current_worker = self.user.manager
  end

  def modify_permissions
    if revocation?
      self.user.permissions.delete(self.permission_requests.map(&:permission))
    else
      self.user.permissions << self.permission_requests.map(&:permission)
    end
  end

  def revocation?
    self.request_action == ACTIONS[:revoke]
  end

  def for_transfer?
    self.reason == REASONS[:transfer]
  end
  
  def for?(this_user)
    self.user == this_user
  end

  def created_for_self?
    self.user == self.created_by
  end

  def created_by?(user)
    self.created_by == user
  end

  def approved_by_manager?
    self.permission_requests.any? {|pr| pr.approved_by_manager? }
  end

  def approved_by_resource_owner?
    self.permission_requests.any? {|pr| pr.approved_by_resource_owner? }
  end

  def reviewed_by_manager?
    self.permission_requests.all? {|pr| !pr.approved_by_manager.nil? }
  end

  def reviewed_by_resource_owner?
    self.permission_requests.approved_by_manager.all? {|pr| !pr.approved_by_resource_owner.nil? }
  end
  
  def mark_complete
    self.completed_at = Time.now
    self.completed_by = current_worker
    unassign_current_worker
  end

  def past_manager_review?
    ['waiting_for_resource_owner_assignment', 'waiting_for_resource_owner', 'waiting_for_help_desk_assignment', 'waiting_for_help_desk', 'completed', 'denied', 'canceled'].include?(self.current_state)
  end

  def past_resource_owner_review?
    ['waiting_for_help_desk_assignment', 'waiting_for_help_desk', 'completed', 'denied', 'canceled'].include?(self.current_state)
  end
  
  def assign_to(user)
    self.current_worker = user
    case self.aasm_current_state      
    when :waiting_for_manager, :waiting_for_resource_owner_assignment
      self.resource_owner = user
      self.assign_to_resource_owner!
    when :waiting_for_help_desk_assignment
      self.help_desk = user
      self.assign_to_help_desk!
    when :waiting_for_help_desk
      # this happens every once in awhile. think it's happening because of people opening up multiple tabs at once and clicking through
    else
      raise "Attempted to assign #{user.login} to access_request #{self.id}, but there is no #{self.current_state} state for access_requests"
    end
  end

  def can_only_be_viewed_by?(user)
    return true if self.for?(user)
    case self.aasm_current_state
    when :waiting_for_manager
      self.manager != user && !user.descendants.include?(self.manager)
    when :waiting_for_resource_owner_assignment
      !user.resources.include?(self.resource) && !user.descendants.detect {|desc| desc.resources.include?(self.resource) }
    when :waiting_for_resource_owner
      !self.resource.users.include?(user) && !user.descendants.detect {|desc| desc.resources.include?(self.resource) }
    when :waiting_for_help_desk_assignment
      !user.help_desk?
    when :waiting_for_help_desk
      self.help_desk != user
    else
      true
    end
  end

  def can_be_canceled_by?(user)
    !self.finished? && (self.user == user || self.created_by == user || (self.waiting_for_help_desk? && user.help_desk? || self.user.ancestors.include?(user)))
  end
  
  # Email Reminder methods below
  def self.age_check(request,type)
    return true if request.updated_at < Time.now-(type.to_i*3600)
    return false
  end

  def self.remind_managers
    manager = [] # collect access requests waiting for manager approval
    AccessRequest.waiting_for_manager.map { |a|
    if age_check(a,'24')
      manager << [a.current_worker, AccessRequest.waiting_for_manager.select { |a1| a1.current_worker == a.current_worker }.size ]
    end
    }
    manager.uniq!
    manager.each do |manager,count|
      AccessRequestMailer.remind_manager_of_pending_acf(manager,count).deliver
    end
  end

  def self.remind_owners
    owner = [] # collect access requests waiting for owner approval
    AccessRequest.waiting_for_resource_owner.map { |a|
    if age_check(a,'24')
      owner << [a.current_worker, AccessRequest.waiting_for_resource_owner.select { |a1| a1.current_worker == a.current_worker }.size, a.current_worker.resources.map {|re| re.name } ]
    end
    }
    owner.uniq!
    owner.each do |owner,count,resources|
      AccessRequestMailer.remind_owner_of_pending_acf(owner,count,resources).deliver
    end
  end

  def self.remind_helpdesk
    help_desk = [] # collect access requests waiting for help desk completion
    AccessRequest.waiting_for_help_desk.map { |a|
      if age_check(a,'24')
        help_desk << [a.current_worker, AccessRequest.waiting_for_help_desk.select { |a1| a1.current_worker == a.current_worker }.size ]
      end
    }
    help_desk.uniq!
    help_desk.each do |help_desk,count|
      begin
      AccessRequestMailer.remind_assignee_of_incomplete_acf(help_desk,count).deliver
      rescue Exception => err
        logger.error(err.message)
      end
    end
  end

  def self.annoy_resource_owners
    waiting_for_owners = []
    AccessRequest.waiting_for_resource_owner_assignment.each do |request|
      waiting_for_owners << request.resource if age_check(request, '24')
    end
    waiting_for_owners.uniq.each do |resource|
      resource.users.each do |owner|
        AccessRequestMailer.remind_resource_owners_of_unassigned_acf(owner, resource.access_requests.not_completed.size, resource).deliver
      end
    end
  end

  def self.annoy_helpdesk
    User.help_desk.each do |help_desk_user|
      AccessRequestMailer.remind_help_desk_of_unassigned_acf(help_desk_user,AccessRequest.waiting_for_help_desk_assignment.size).deliver
    end
  end

  def self.annoy_managers
    one_up_reminders = [] # collect requests for escalation
    AccessRequest.not_completed.map {|a|
      if age_check(a,'48') && !a.current_worker_id.nil?
        one_up_reminders << [a.current_worker, AccessRequest.not_completed.select { |a1| a1.current_worker == a.current_worker }.size ]
      end
    }
    one_up_reminders.uniq!
    one_up_reminders.each do |user,count|
      AccessRequestMailer.notify_1_up_manager(user,count).deliver
    end
  end
end
