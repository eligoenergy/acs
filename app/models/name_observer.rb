class NameObserver < ActiveRecord::Observer
  observe :company, :department, :job, :location, :permission_type, :resource_group, :resource, :user
  
  def before_validation(record)
    if record.is_a? PermissionType
      record.name = record.name.downcase
    else
      record.name = record.name.titleize if record.respond_to?(:name)
    end
    record.last_name.strip if record.respond_to?(:last_name)
    record.first_name.strip if record.respond_to?(:first_name)
  end
end
