class UserObserver < ActiveRecord::Observer

  def before_update(record)
    @record = record
    if @record.current_state_changed?
      case @record.aasm_current_state
      when :passive
        
      when :pending
        
      when :active
        clear_terminated_at
      when :suspended
        
      when :terminated
	
      else
        raise "state #{@record.current_state} does not exist or has not been added to before_update user_observer for #{@record.inspect}"
      end
    end
  end
  
  def after_update(record)
    @record = record
    if @record.current_state_changed?
      case @record.aasm_current_state
      when :passive
        
      when :pending
        notify_hr_of_creation
      when :active
        
      when :suspended
        notify_hr_of_termination
      when :terminated
	
      else
        raise "state #{@record.current_state} does not exist or has not been added to after_update user_observer for #{@record.inspect}"
      end
    end
  end

  def clear_terminated_at
    @record.terminated_by = nil
  end
  
  def notify_hr_of_termination
    User.hr.all.each do |hr_user|
      UserMailer.notify_hr_of_user_termination_by_manager(@record, hr_user).deliver
    end
  end
  
  def notify_hr_of_creation
    User.hr.all.each do |hr_user|
      UserMailer.notify_hr_of_user_creation(@record, hr_user).deliver
    end
  end  
end

