module AccessRequests
  module StateMachineHelper
    def aasm_event_failed(name, old_state_name)
      msg = "Access Request #{self.id} failed to transition on event, #{name}!, from state, #{old_state_name.to_sym}"
      msg += "\n Error: #{self.errors.inspect}"
      ::ApplicationController.logger.info { msg }
      raise msg
    end

    def created_by_manager_for_new_employee?
      self.request.created_by_manager_for_subordinate? && self.user.new_employee?
    end
        
    def can_go_directly_to_help_desk?
      self.request.goes_directly_to_help_desk? || self.created_by_import
    end
    
    def created_by_manager_to_terminate_current_user
      self.request.reason == Request::REASONS[:termination] && self.request.created_by_manager_for_subordinate?
	  end
    
    def resource_has_one_owner?
      self.resource.users.count == 1
    end
  end
end
