module AdvantageQuickbase
  class API
    module Table
      def find_db_by_name(name)
        result = send_request( :FindDBByName, "main", { :dbname => name } )
        get_tag_value(result, :dbid)
      end

      def get_db_info(db_id)
        result = send_request( :GetDBInfo, db_id, {})

        {
          :name => get_tag_value(result, "dbname"),
          :last_modified_record => get_tag_value(result, "lastrecmodtime"),
          :last_modified_time => get_tag_value(result, "lastmodifiedtime"),
          :created_time => get_tag_value(result, "createdtime"),
          :number_of_records => get_tag_value(result, "numrecords"),
          :manager => get_tag_value(result, "mgrid"),
          :manager_name => get_tag_value(result, "mgrname"),
          :version => get_tag_value(result, "version"),
          :time_zone => get_tag_value(result, "time_zone"),
        }
      end

      def get_role_info(db_id)
        roles = []
        result = send_request( :GetRoleInfo, db_id, {})

        result.css( 'role' ).each do |role|
          roles << {
            :id => get_attr_value(role, :id),
            :name => get_tag_value(role, :name),
            :access => get_tag_value(role, :access)
          }
        end

        roles
      end

      def get_users_access(db_id)
        users = []
        result = send_request( :UserRoles, db_id, {})

        result.css( 'user' ).each do |user|
          users << {
            :id => get_attr_value(user, :id),
            :last_access => get_tag_value(user, :lastaccess),
            :first_name => get_tag_value(user, :firstname),
            :last_name => get_tag_value(user, :lastname),
            :roles => { :id => get_attr_value(get_tag_value(user.css( 'role' ), :id), :name => get_tag_value(user.css( 'role' ), :name), :access => get_tag_value(user.css( 'role' ), :access)}
          }
        end

        users
      end
    end
  end
end