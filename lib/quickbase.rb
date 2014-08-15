require 'net/https'
require 'nokogiri'
require 'json'
require 'csv'
require 'base64'

require_relative 'user'
require_relative 'table'

module AdvantageQuickbase
  class API

    attr_accessor :options, :ticket, :app_token

    include User
    include Table

    def initialize( domain, username, password, app_token=nil, ticket=nil, options={} )
      @options = {
        numeric_keys: false
      }

      @connection = Connection.new( domain, username, password, app_token, ticket )
    end

    def do_query_count( db_id, query )
      result = @qb_api.send_request( :doQueryCount, db_id, {query: query} )
      get_tag_value( result, :nummatches ).to_i
    end

    def find( db_id, rid, options={} )
      options[:query] = "{'3'.EX.'#{rid}'}"
      records = self.do_query( db_id, options )

      if records.length > 0
        return records.first
      else
        return {}
      end
    end

    def do_query( db_id, options )
      # Define the query format
      if !options[ :fmt ]
        options[ :fmt ] = 'structured'
      end

      # Normalize the field list variables into period-separated strings
      options[ :clist ] = normalize_list( options[:clist] )
      options[ :slist ] = normalize_list( options[:slist] )

      # Empty clist now loads all columns instead of "default"
      if options[ :clist ].empty?
        options[ :clist ] = 'a'
      end

      result = @qb_api.send_request( :doQuery, db_id, options )

      return_json = []
      result.css( 'record' ).each do |record|
        json_record = {}
        record.css( 'f' ).each do |field|
          json_record[ field['id'] ] = field.text
        end

        return_json << json_record
      end

      return_json
    end

    def add_record( db_id, new_values )
      xml = @qb_api.build_update_xml( new_values )
      result = @qb_api.send_request( :addRecord, db_id, nil, xml )

      get_tag_value( result, :rid )
    end

    def edit_record( db_id, record_id, new_values )
      xml = @qb_api.build_update_xml( new_values, record_id )
      result = @qb_api.send_request( :editRecord, db_id, nil, xml )

      get_tag_value( result, :rid ).to_s == record_id.to_s
    end

    def delete_record( db_id, record_id )
      result = @qb_api.send_request( :deleteRecord, db_id, {rid: record_id} )

      get_tag_value( result, :rid ).to_s == record_id.to_s
    end

    def purge_records ( db_id, options={} )
      if options.length == 0
        options[ :query ] = ''
      end

      result = @qb_api.send_request( :purgeRecords, db_id, options )

      get_tag_value( result, :num_records_deleted ).to_s
    end

    def create_app_token(db_id, description, page_token)
      url = "https://#{base_domain}/db/main?a=QBI_CreateDeveloperKey"

      result = send_quickbase_ui_action(url)
      result = parse_xml( result.body )

      app_token = get_tag_value(result, "devkey")

      url = URI::encode("https://#{base_domain}/db/#{db_id}?a=QBI_AddApplicationDeveloperKey&devKey=#{app_token}&keydescription=#{description}&keyType=P&PageToken=#{page_token}")

      result = send_quickbase_ui_action(url)
      result = parse_xml( result.body )

      app_token
    end

    def import_from_csv( db_id, import_data, columns=nil )
      # If import_data contains hashes, use the keys as the import headers
      columns ||= import_data[ 0 ].map{ |fid, value| fid }
      columns = normalize_list( columns )

      xml = @qb_api.build_csv_xml( import_data, columns )

      result = @qb_api.send_request( :importFromCSV, db_id, nil, xml )
      result.css('rid').map{ |xml_node| xml_node.text.to_i }
    end

    def get_schema( db_id )
      schema_hash = {}
      result = @qb_api.send_request( :getSchema, db_id, {} )

      # Get the table data
      schema_hash[ :app_id ] = get_tag_value( result, 'app_id' )
      schema_hash[ :table_id ] = get_tag_value( result, 'table_id' )
      schema_hash[ :name ] = get_tag_value( result, 'name' )

      if schema_hash[ :app_id ] == schema_hash[ :table_id ]
        # App Mode
        schema_hash[ :mode ] = 'app'

        schema_hash[ :tables ] = {}
        tables = result.css( 'chdbid' )
        tables.each do |table|
          table_hash = {
            dbid: table.text,
            name: table.attributes['name'].to_s
          }

          table_hash[ :name ].gsub!( /^_dbid_/, '' )
          table_hash[ :name ].gsub!( '_', ' ' )
          table_hash[ :name ].capitalize!

          schema_hash[ :tables ][ table_hash[:dbid] ] = table_hash
        end
      else
        # Table mode
        schema_hash[ :mode ] = 'table'

        # Parse the field data
        schema_hash[ :fields ] = {}

        fields = result.css( 'field' )

        fields.each do |field|
          field_hash = {
            id: field.attributes[ 'id' ].to_s,
            data_type: field.attributes[ 'field_type' ].to_s,
            base_type: field.attributes[ 'base_type' ].to_s,
            name: get_tag_value( field, 'label' ),
            required: get_tag_value( field, 'required' ).to_i == 1,
            unique: get_tag_value( field, 'unique' ).to_i == 1,
          }

          # Field type (Summary, Formula, Lookup, etc) is poorly represented. Fix that.
          case field.attributes[ 'mode' ].to_s
          when 'virtual'
            field_hash[ :field_type ] = 'formula'
          when ''
            field_hash[ :field_type ] = 'normal'
          else
            field_hash[ :field_type ] = field.attributes[ 'mode' ].to_s
          end

          choices = field.css( 'choice' )
          if choices.length > 0
            field_hash[ :choices ] = []
            choices.each do |choice|
              field_hash[ :choices ] << choice.text
            end
          end

          schema_hash[ :fields ][ field_hash[:id] ] = field_hash
        end

        #Parse the report data
        schema_hash[ :reports ] = {}
        reports = result.css( 'query' )
        reports.each do |report|
          report_hash = {
            id: report.attributes[ 'id' ].to_s,
            name: get_tag_value( report, 'qyname' ),
            type: get_tag_value( report, 'qytype' ),
            criteria: get_tag_value( report, 'qycrit' ),
            clist: get_tag_value( report, 'qyclst' ),
            slist: get_tag_value( report, 'qyslst' )
          }

          schema_hash[ :reports ][ report_hash[:id] ] = report_hash
        end
      end

      schema_hash
    end

    # Helper functions for parsing or formatting data IO
    private
    def normalize_list( list )
      if list.is_a?( Array )
        list = list.map { |fid| fid.to_s }.join( '.' )
      elsif list.is_a?( Hash )
        list = list.map { |name, fid| fid.to_s }.join( '.' )
      elsif list.to_s.empty?
        list = ''
      end
      list
    end

    def encode_file( path_or_content )
      # File accepts either file content or a file path
      if File.file?( path_or_content )
        file_content = File.open(path_or_content, 'rb') { |f| f.read }
      else
        file_content = path_or_content
      end

      Base64.strict_encode64( file_content )
    end

    def parse_xml( xml )
      Nokogiri::HTML( xml )
    end

    def get_tag_value( xml, tag_name )
      tag = xml.css( tag_name.to_s )

      tag_value = nil
      if !tag.empty?
        tag_value = tag.text
      end

      tag_value
    end

    def get_attr_value(tag, attr_name)
      attr_value = tag.attribute(attr_name.to_s).to_s
    end
  end
end
