class AccessRequestObserver < ActiveRecord::Observer

  def before_update(record)
    @record = record
    # ::ApplicationController::logger.info { "\n\n\n** #{@record.inspect}\n* changed? #{@record.current_state_changed?}\n* state: #{@record.current_state}"}
    if @record.current_state_changed?
      case @record.aasm_current_state
      when :waiting_for_resource_owner
        @record.current_worker = @record.resource_owner
      when :waiting_for_help_desk_assignment
        @record.unassign_current_worker
      when :completed
        mark_complete
      end
    end
  end
  
  def after_update(record)
    @record = record
    if @record.current_state_changed?
      case @record.aasm_current_state        
      when :waiting_for_manager
        # shouldn't have to do anything here, mailing to manager is taken care
        # of via the request_observer so only one email is sent
      when :waiting_for_resource_owner_assignment
        # AccessRequestMailer.notify_user_of_manager_approval(@record).deliver
        notify_resource_owners
      when :waiting_for_resource_owner
        if @record.resource.has_one_owner?
          AccessRequestMailer.notify_resource_owner_of_assignment(@record).deliver
        end
      when :waiting_for_help_desk_assignment
        notify_help_desk unless @record.request.goes_directly_to_help_desk?
      when :waiting_for_help_desk

      when :canceled
        # AccessRequestMailer.notify_manager_of_canceled_access_request(@record).deliver unless @record.reviewed_by_manager?
        # elsif @record.waiting_for_resource_owner? || @record.waiting_for_resource_owner_assignment?
          # AccessRequestMailer.notify_manager_of_canceled_access_request(@record).deliver          
        # end
        update_request_status
      when :completed
        modify_permissions
        update_request_status
        # AccessRequestMailer.notify_user_of_completed_request(@record).deliver
        # AccessRequestMailer.notify_manager_of_completed_request(@record).deliver
        # AccessRequestMailer.notify_resource_owner_of_completed_request(@record).deliver
      when :denied
        @record.mark_complete
        AccessRequestMailer.notify_user_of_request_denial(@record).deliver
        update_request_status
      else
        raise "something went wrong with access request #{@record.inspect}"
      end
    end
  end

  def update_request_status
    if @record.request.access_requests.all? {|access_request| access_request.finished? }
      @record.request.complete!
    end
    # TODO need to notify related parties of all complete
  end

  def notify_resource_owners
    @record.resource.users.each do |owner|
      AccessRequestMailer.request_needs_owner_assignment(@record, owner).deliver
    end
  end

  def notify_help_desk
    User.active.help_desk.all.each do |help_desk_user|
      AccessRequestMailer.request_needs_help_desk_assignment(@record, help_desk_user).deliver
    end
  end
  
  def mark_complete
    @record.completed_by = @record.current_worker
    @record.current_worker = nil
    @record.completed_at = Time.now
  end
  
  def modify_permissions
    if @record.revocation?
      @record.request.user.permissions.delete(@record.permission_requests.map{|pr| pr.permission })
    else
      @record.approved_permission_requests.each do |pr|
        pr.update_attribute(:permission_granted, true)
        # I thought << respected the :uniq => true option, but apparently it doesn't
        # TODO find the correct rails way or db way to do this and not need the unless... part
        @record.request.user.permissions << pr.permission unless @record.request.user.permissions.include?(pr.permission) || !pr.permission.activated?
      end
    end
  end
end

