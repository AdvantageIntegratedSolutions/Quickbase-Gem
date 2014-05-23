module AdvantageQuickbase
  class API
    module User
      def get_user_info(email)
        user = send_request( :GetUserInfo, "main", { :email => email })
        user = {
          :id => get_attr_value(user.css("user"), :id),
          :first_name => get_tag_value(user, :firstname),
          :last_name => get_tag_value(user, :lastname),
          :login => get_tag_value(user, :login),
          :email => get_tag_value(user, :email),
          :screen_name => get_tag_value(user, :screenname),
        }
      end

      def get_user_role(db_id, user_id)
        roles = []
        result = send_request(:GetUserRole, db_id, { :userid => user_id })

        result.css( 'role' ).each do |role|
          roles << role = { 
            :id => get_attr_value(role, :id), 
            :name => get_tag_value(role, :name), 
            :type => get_tag_value(role, :access )
          }
        end

        roles
      end

      def add_user_to_role(db_id, user_id, role_id)
        send_request(:AddUserToRole, db_id, { :userid => user_id, :roleid => role_id }) 
      end

      def remove_user_from_role(db_id, user_id, role_id)
        send_request(:RemoveUserFromRole, db_id, { :userid => user_id, :roleid => role_id })
      end

      def change_user_role(db_id, user_id, role_id, new_role_id=nil)
        send_request(:ChangeUserRole, db_id, { :userid => user_id, :roleid => role_id, :newroleid => new_role_id })
      end

      def provision_user(db_id, email, role_id=nil, first_name=nil, last_name=nil)
        options = {
          :email => email,
          :roleid => role_id,
          :first_name => first_name, 
          :last_name => last_name
        }

        send_request(:ProvisionUser, db_id, options)
      end

      def get_app_access()
        tables = []
        result = send_request(:GrantedDBs, "main", {})

        result.css( 'dbinfo' ).each do |database|
          tables << { :name => get_tag_value(database, "dbname"), :db_id => get_tag_value(database, "dbid") }
        end

        tables
      end

      def remove_access(db_id, email)
        user = self.get_user_info(email)
        roles = get_user_role(db_id, user[:id])

        roles.each do |role|
          self.remove_user_from_role(db_id, user[:id], role[:id])
        end
      end

      def deny_users(account_id, emails)
        user_ids = get_user_ids(emails);

        url = "https://#{base_domain}/db/main?a=QBI_AccountRemoveMultiUserAccess"
        url += "&accountid=#{account_id}"
        url += "&removeAction=deny"
        url += "&uids=" + user_ids.join(",")

        result = send_quickbase_ui_action(url)
        result = parse_xml( result.body )

        get_tag_value(result, "numchanged")
      end

      def undeny_users(account_id, emails)
        user_ids = get_user_ids(emails);

        url = "https://#{base_domain}/db/main?a=QBI_AccountRemoveMultiUserAccess"
        url += "&accountid=#{account_id}"
        url += "&removeAction=allow"
        url += "&uids=" + user_ids.join(",")

        result = send_quickbase_ui_action(url)
        result = parse_xml( result.body )

        get_tag_value(result, "numchanged")
      end

      def get_user_ids(emails)
        user_ids = emails.map do |email|
          self.get_user_info(email)[:id]
        end
      end
    end
  end
end