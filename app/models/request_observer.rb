class RequestObserver < ActiveRecord::Observer

  def before_update(record)
    @record = record
    if @record.current_state_changed?
      case @record.aasm_current_state
      when :completed
        @record.completed_at = Time.now
      end
    end
  end
  
  def after_update(record)
    @record = record
    #::ApplicationController::logger.info { "\n\n\n** request #{@record.inspect}\n* changed? #{@record.current_state_changed?}\n* state: #{@record.current_state}"}
    
    if @record.current_state_changed?
      case @record.aasm_current_state        
      when :in_progress
        @record.order_access_requests_by_resource_name!
        if @record.goes_directly_to_help_desk?
          @record.access_requests.each {|a| a.send_to_help_desk! }
          notify_help_desk
        elsif @record.created_by_manager_for_subordinate?
          # TODO FIXME need to figure out how best to notify resource owners without spamming
          # notify_resource_owners
          @record.access_requests.each do |access_request|
            if access_request.resource.has_one_owner?
              access_request.assign_to(access_request.resource.users.first)
            else
              access_request.send_to_resource_owners!
            end
          end
        elsif @record.created_for_self?
          @record.access_requests.each {|access_request| access_request.assign_to_manager! }
          RequestMailer.notify_manager(@record).deliver
        end
        RequestMailer.request_receipt(@record).deliver if @record.reason?(:standard)
      when :completed
        RequestMailer.request_complete(@record).deliver if @record.reason?(:standard)
      end
    end
  end
  
  def notify_resource_owners
    @record.access_requests.each do |access_request|
      access_request.resource.users.each do |user|
        RequestMailer.notify_resource_owner(@record, user).deliver
      end
    end
  end
  
  def notify_help_desk
    User.active.help_desk.all.each do |help_desk_user|
      case @record.reason
      when 'termination'
        RequestMailer.notify_help_desk_of_terminated_user(@record, help_desk_user).deliver
      when 'new_hire'
        RequestMailer.notify_help_desk_of_new_user(@record, help_desk_user).deliver
      else
        RequestMailer.notify_help_desk(@record, help_desk_user).deliver
      end
    end
  end
    
end