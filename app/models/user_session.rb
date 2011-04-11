class UserSession < Authlogic::Session::Base
  verify_password_method :valid_ldap_credentials? if LDAP[Rails.env][:active]

  def to_key
    new_record? ? nil : [ self.send(self.class.primary_key) ]
  end

  def persisted?
    false
  end
end

