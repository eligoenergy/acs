module Acs
  module Ldap

    def self.included(base)
      base.send :extend, Acs::Ldap::ClassMethods
      base.send :include, Acs::Ldap::InstanceMethods
    end

    module ClassMethods
      def ldap
        @ldap ||= Net::LDAP.new(
          :host       => App.ldap[:host],
          :port       => App.ldap[:port],
          :base       => App.ldap[:domain],
          :encryption => App.ldap[:encryption]
        )
      end
      def ldap_active?
        ::App.ldap[:active]
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
        if existing_logins.blank?
          username
        else
          # if logins aren't blank and the last existing login does not have
          # a digit already, then this user will be the second user with that
          # first_letter last_name combo. There was a user with the name ljohnson1
          # but there was never an ljohnson, so the user couldn't be created
          # the previous way this worked as this would try to create another
          # ljohnson1 instead of the next ljohnson2. This should fix that.
          digit = existing_logins.last.scan(/\d$/).first
          if digit.blank? 
            "#{username}1"
          else
            username.concat((digit.to_i + 1).to_s)
          end
        end
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
        App.ldap[:uid]
      end

      def domain
        App.ldap[:domain]
      end
    end
  end
end

