class PermissionRequest < ActiveRecord::Base
  belongs_to :access_request
  belongs_to :permission
  belongs_to :manager, :class_name => 'User'
  belongs_to :resource_owner, :class_name => 'User'

#  acts_as_change_logger

  attr_accessible :approved, :permission_id, :approved_by_manager_at, :approved_by_manager, :approved_by_resource_owner_at, :approved_by_resource_owner

  delegate :created_by_manager_for_subordinate?, :to => :access_request
  
  scope :approved_by_manager, where(:approved_by_manager => true)
  scope :denied_by_manager, where('approved_by_manager is not null and approved_by_manager = ?', false)
  scope :reviewed_by_manager, where('approved_by_manager is not null')
  scope :approved_by_resource_owner, where(:approved_by_resource_owner => true)
  scope :denied_by_resource_owner, where('approved_by_resource_owner is not null and approved_by_resource_owner = ?', false) #:approved_by_resource_owner => false)
  scope :granted, where(:permission_granted => true)

  def approval(reason, val)
    return false if val.nil?
    send(self.access_request.current_state, reason, val)
    self.save
  end
  
  def pending(reason, val)
    case reason
    when 'standard'
      if self.created_by_manager_for_subordinate?
        manager_decision(val)
      end
    when 'revoke'
      manager_decision(val)
    when 'new_hire'
      if self.created_by_manager_for_subordinate?
        manager_decision(val, self.created_at)
      end
      hr_decision(val)
    when 'rehire'
      hr_decision(true)
    when 'termination'
      if self.access_request.request.created_by.hr?
        hr_decision(val)
      elsif self.created_by_manager_for_subordinate?
        manager_decision(val)
      else
        raise "pending termination requests must be created by hr or the employees manager"
      end
    else
      raise "not sure how to handle a pending access request for #{reason}"
    end
  end
  
  def waiting_for_manager(reason, val)
    case reason
    when 'standard'
      manager_decision(val)
    else
      raise "not sure how to handle access request that is waiting_for_manager with reason #{reason}"
    end
  end
  
  def waiting_for_resource_owner(reason, val)
    case reason
    when 'standard'
      resource_owner_decision(val)
    else
      raise "not sure how to handle access request that is waiting_for_resource_owner with reason #{reason}"
    end
  end
  
  def hr_decision(val, time = nil)
    self.approved_by_hr = val
    self.approved_by_hr_at = time || Time.now
  end
  
  def manager_decision(val, time = nil)
    self.approved_by_manager = val
    self.approved_by_manager_at = time || Time.now
  end
  
  def resource_owner_decision(val, time = nil)
    self.approved_by_resource_owner = val
    self.approved_by_resource_owner_at = time || Time.now    
  end
end

