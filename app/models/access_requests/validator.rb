module AccessRequests
  class Validator < ActiveModel::Validator
    def validate(record)
      @record = record
      # if a user can't actively change the value of an attribute, it shouldn't be validated here, but I have done that for a few attributes below anyway, just in case. need to investigate further
      @record.errors[:base] << "An Access Request needs to be for a resource" if @record.resource.blank?
      @record.errors[:base] << "An Access Request must grant or deny access" if @record.request_action.blank?
      @record.errors[:base] << "You must select at least one permission" if @record.permission_requests.any? {|permission_request| permission_request.permission_id.nil? }
      unless record.pending?
        @record.errors[:base] << "An Access Request requires at least one permission request" if @record.permission_requests.blank?
      end
      # record.errors[:base] << "An Access Request cannot be created for a permission that is already granted" if record.user.permissions.any? {|permission| record.permission_requests.any? {|pr| pr.permission == permission } }

      validate_does_not_already_have_access unless @record.user.blank?
      validate_resource_has_an_owner unless @record.resource.blank?
      validate_no_open_requests_for_this_resource unless @record.user.blank?
      validate_manager_approval if @record.need_to_validate_manager_approval?
      validate_resource_owner_approval if @record.need_to_validate_resource_owner_approval?

      case record.aasm_current_state
      when :pending

      when :for_termination

      when :waiting_for_hr

      when :waiting_for_hr_assignment

      when :waiting_for_manager

      when :waiting_for_resource_owner_assignment

      when :waiting_for_resource_owner

      when :waiting_for_help_desk_assignment
        validate_not_for_current_worker
      when :waiting_for_help_desk
        validate_not_for_current_worker
      when :canceled

      when :completed

      when :denied

      else
        raise "unknown access_request state in access_request_validator: #{@record.current_state}"
      end
    end

    def validate_resource_has_an_owner
      if @record.resource.does_not_have_any_owners?
        @record.errors[:base] << "Can't request access to resource with no owners"
      end
    end

    def validate_does_not_already_have_access
      @record.request.user.permissions.any? do |permission|
        @record.permission_requests.any? {|pr| pr.permission == permission }
      end
    end

    def validate_permission_requests_arent_blank
      @record.permission_requests.any? do |permission_request|
        if permission_request.permission_id.blank?
          @record.errors[:base] << "You must select at least one permission"
        end
      end
    end

    def validate_no_open_requests_for_this_resource
      # if statement below will check for access_requests with same permission, may be better to do it that way, but will revisit in the future
      if @record.request.user.access_requests.not_completed.but_not(@record).any? {|ar| ar.permission_requests.any? {|pr| @record.permission_requests.map(&:permission).include?(pr.permission) } } #@record.resource == ar.resource }
      #if @record.user.access_requests.not_completed.but_not(@record).any? {|ar| @record.resource == ar.resource }
        @record.errors[:base] << "An employee can not have two Access Requests for the same permission open at the same time"
      end
    end

    def validate_not_for_current_worker
      if @record.request.user == @record.current_worker
        @record.errors[:base] << "You can't process an Access Request that is for you"
      end
    end

    def validate_manager_approval
      @record.permission_requests.each do |permission_request|
        @record.errors.add(:base, "Please approve or deny #{permission_request.permission.permission_type.name} access.") if permission_request.approved_by_manager.nil?
      end
    end

    def validate_resource_owner_approval
      @record.permission_requests.approved_by_manager.each do |permission_request|
        @record.errors.add(:base, "Please approve or deny #{permission_request.permission.permission_type.name} access.") if permission_request.approved_by_resource_owner.nil?
      end
    end
  end
end

