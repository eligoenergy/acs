class AccessRequestObserver < ActiveRecord::Observer

  def before_update(record)
    @record = record
    ::ApplicationController::logger.info { "\n\n\n** #{@record.inspect}\n* changed? #{@record.current_state_changed?}\n* state: #{@record.current_state}"}
    if @record.current_state_changed?
      case @record.aasm_current_state
      when :waiting_for_resource_owner
        @record.current_worker = @record.resource_owner
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
        AccessRequestMailer.send_access_request_receipt(@record).deliver
        AccessRequestMailer.notify_manager_of_pending_acf(@record).deliver
      when :waiting_for_resource_owner_assignment
        AccessRequestMailer.notify_user_of_manager_approval(@record).deliver
        notify_resource_owners
      when :waiting_for_resource_owner
        AccessRequestMailer.notify_resource_owner_of_assignment(@record).deliver
      when :waiting_for_help_desk_assignment        
        notify_help_desk                
      when :waiting_for_help_desk

      when :canceled
        # AccessRequestMailer.notify_manager_of_canceled_access_request(@record).deliver unless @record.reviewed_by_manager?
        # elsif @record.waiting_for_resource_owner? || @record.waiting_for_resource_owner_assignment?
          # AccessRequestMailer.notify_manager_of_canceled_access_request(@record).deliver          
        # end
      when :completed
        complete_request
        # AccessRequestMailer.notify_user_of_completed_request(@record).deliver
        # AccessRequestMailer.notify_manager_of_completed_request(@record).deliver
        # AccessRequestMailer.notify_resource_owner_of_completed_request(@record).deliver
      when :denied
        @record.mark_complete
        AccessRequestMailer.notify_user_of_request_denial(@record).deliver
      else
        raise "something went wrong with access request #{@record.inspect}"
      end
    end
  end

  def notify_resource_owners
    @record.resource.users.each do |owner|
      AccessRequestMailer.request_needs_owner_assignment(@record, owner).deliver
    end
  end

  def notify_help_desk
    User.help_desk.all.each do |help_desk_user|
      AccessRequestMailer.request_needs_help_desk_assignment(@record, help_desk_user).deliver
    end
  end
  
  def mark_complete
    @record.completed_by = @record.current_worker
    @record.current_worker = nil
    @record.completed_at = Time.now
  end
  
  def complete_request
    if @record.revocation?
      @record.user.permissions.delete(@record.permission_requests.map{|pr| pr.permission })
    else
      @record.permission_requests.approved_by_resource_owner.all.each do |pr|
        pr.update_attribute(:permission_granted, true)
        # I thought << respected the :uniq => true option, but apparently it doesn't
        # TODO find the correct rails way or db way to do this and not need the unless... part
        @record.user.permissions << pr.permission unless @record.user.permissions.include?(pr.permission)
      end
    end
  end
end

