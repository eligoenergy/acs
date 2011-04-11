module Acs
  module Ldap
    CONFIG = YAML.load(File.open(File.join(Rails.root.to_s,'config/ldap.yml')))

    def self.included(base)
      base.send :extend, Acs::Ldap::ClassMethods
      base.send :include, Acs::Ldap::InstanceMethods
    end

    module ClassMethods
      def ldap
        @ldap ||= Net::LDAP.new(
          :host       => Acs::Ldap::CONFIG[:host],
          :port       => Acs::Ldap::CONFIG[:port],
          :base       => Acs::Ldap::CONFIG[:domain],
          :encryption => Acs::Ldap::CONFIG[:encryption]
        )
      end
      def ldap_active?
        CONFIG[Rails.env]['active']
      end
    end

    module InstanceMethods
      def generate_unique_login
        username = "#{first_name[0].chr.downcase}#{last_name.downcase}"
        # TODO this test specific code doesn't really belong here, need to move it to tests
        return username unless self.class.ldap_active?
        existing_logins = ldap_connection.search(
          :base => ldap_connection.base,
          :filter => ldap_filter(username) ).map { |r| r.uid[0] }
        existing_logins.blank? ? username : username.concat(existing_logins.length.to_s)
      end

      def valid_ldap_credentials?(password)
        # try to authenticate against the LDAP server
        ldap_connection.auth "#{uid} = #{self.login}, #{domain}", password
        unless ldap_connection.bind # will return false if authentication is NOT successful
          logger.error("LDAP AUTHENTICATION FAILURE: Failed Login Attempt for #{self.login}") and return false
        else
          true
        end
      end

      def ldap_connection
        self.class.ldap
      end

      def ldap_filter(username)
        Net::LDAP::Filter.eq(uid, "#{username}*" )
      end

      def uid
        Acs::Ldap::CONFIG[:uid]
      end

      def domain
        Acs::Ldap::CONFIG[:domain]
      end
    end
  end
end

