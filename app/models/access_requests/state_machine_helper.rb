module AccessRequests
  module StateMachineHelper
    def aasm_event_failed(name, old_state_name)
      msg = "Access Request #{self.id} failed to transition on event, #{name}!, from state, #{old_state_name.to_sym}"
      msg += "\n Error: #{self.errors.inspect}"
      ::ApplicationController.logger.info { msg }
      raise msg
    end

    def created_by_manager_for_new_employee?
      self.by_manager_for_subordinate? && self.user.new_employee?
    end
    
    def created_for_new_or_rehire_employee_or_termination?
      ((self.created_by.hr? || self.by_manager_for_subordinate?) && (self.user.new_employee? || self.reason == AccessRequest::REASONS[:termination] || self.reason == AccessRequest::REASONS[:rehire]))
    end
    
    def can_go_directly_to_help_desk?
      self.created_for_new_or_rehire_employee_or_termination? || self.created_by_import || self.created_by_transfer
    end
    
    def created_by_manager_to_terminate_current_user
      self.reason == AccessRequest::REASONS[:termination] && by_manager_for_subordinate?
	  end
    
    def resource_has_one_owner?
      self.resource.users.count == 1
    end
  end
end
