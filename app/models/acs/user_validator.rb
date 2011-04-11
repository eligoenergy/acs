module Acs
  class UserValidator < ActiveModel::Validator
    def validate(record)
      record.errors[:first_name] << "is required for every employee" if record.first_name.blank?
      record.errors[:last_name] << "is required for every employee" if record.last_name.blank?
      record.errors[:job] << "is required" if record.job.blank?
      record.errors[:roles] << "are required" if record.roles.blank?
      record.errors[:employment_type] << "is required" if record.employment_type.blank?
      # validation below is a bit of a safety net. When creating a user, a similar error should prevent a user from getting to the point where the record is actually saved.
      record.errors[:job] << "must have a template" if !record.nonhuman_flg? && (record.job_id_changed? && record.try(:job).try(:permissions).blank?)
      unless record.first_name.blank? || record.last_name.blank?
        record.errors[:login] << "is required" if record.login.blank?
      end
    end
  end
end

