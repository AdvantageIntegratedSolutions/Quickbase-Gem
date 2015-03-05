require 'net/https'
require 'nokogiri'
require 'json'
require 'csv'
require 'base64'

require_relative 'user'
require_relative 'table'

module AdvantageQuickbase
  class API

    attr_accessor :ticket, :app_token

    include User
    include Table

    def initialize( domain, username, password, app_token=nil, ticket=nil)
      @domain = domain
      @app_token = app_token if app_token

      if username && password #authenticate with username/password
        data = {
          username: username,
          password: password,
          apptoken: app_token
        }
      else #authenticate with existing ticket
        @ticket = ticket if ticket

        data = {}
      end

      request_xml = build_request_xml( data )

      @http = Net::HTTP.new( base_domain, 443 )
      @http.read_timeout = 360
      @http.use_ssl = true
      @http.verify_mode = OpenSSL::SSL::VERIFY_NONE

      url = build_request_url( :authenticate )
      headers = build_request_headers( :authenticate, request_xml )

      result = @http.post( url, request_xml, headers )
      parsed_result = parse_xml( result.body )

      ticket = get_tag_value( parsed_result, :ticket )
      if ticket
        @ticket = ticket
      else
        raise "Connection Failed\n\n#{result.body}"
      end
    end

    def do_query_count( db_id, query )
      result = send_request( :doQueryCount, db_id, {query: query} )
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
      if options.has_key?( :fmt ) && options[:fmt].to_s.strip.empty?
        options.delete :fmt
      else
        options[ :fmt ] = 'structured'
      end

      # Normalize the field list variables into period-separated strings
      options[ :clist ] = normalize_list( options[:clist] )
      options[ :slist ] = normalize_list( options[:slist] )

      # nil clist loads all columns instead of "default"
      if options[ :clist ].nil?
        options[ :clist ] = 'a'
      end

      result = send_request( :doQuery, db_id, options )

      return_json = []
      result.css( 'record' ).each do |record|
        json_record = {}

        record.css( 'f' ).each do |field|
          if options.has_key? :fmt
            # File attachment fields shuold return a hash with keys :filename and :url
            if !field.css("url").text.empty?
              fieldname = Nokogiri::XML.parse(field.to_html.gsub(/<url.*?<\/url>/, "")).text
              value = { filename: fieldname, url: field.css("url").text }
            else
              value = field.text
            end

            json_record[ field['id'] ] = value
          else
            record.element_children.each do |field|
              json_record[ field.node_name ] = value
            end
          end
        end

        return_json << json_record
      end

      return_json
    end

    def add_record( db_id, new_values )
      xml = build_update_xml( new_values )
      result = send_request( :addRecord, db_id, nil, xml )

      get_tag_value( result, :rid )
    end

    def edit_record( db_id, record_id, new_values )
      xml = build_update_xml( new_values, record_id )
      result = send_request( :editRecord, db_id, nil, xml )

      get_tag_value( result, :rid ).to_i > 0
    end

    def delete_record( db_id, record_id )
      result = send_request( :deleteRecord, db_id, {rid: record_id} )

      get_tag_value( result, :rid ).to_i > 0
    end

    def purge_records ( db_id, options={} )
      if options.length == 0
        options[ :query ] = ''
      end

      result = send_request( :purgeRecords, db_id, options )

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
      result = []
      if import_data && import_data.length > 0
        # If import_data contains hashes, use the keys as the import headers
        columns ||= import_data[ 0 ].map{ |fid, value| fid }
        columns = normalize_list( columns )

        xml = build_csv_xml( import_data, columns )

        result = send_request( :importFromCSV, db_id, nil, xml )
        result = result.css('rid').map{ |xml_node| xml_node.text.to_i }
      end

      result
    end

    def get_schema( db_id )
      schema_hash = {}
      result = send_request( :getSchema, db_id, {} )

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

    private
    def normalize_list( list )
      if list.is_a?( Array )
        list = list.map { |fid| fid.to_s }.join( '.' )
      elsif list.is_a?( Hash )
        list = list.map { |name, fid| fid.to_s }.join( '.' )
      end
      list
    end

    def build_request_headers( api_call, request_body )
      {
        'Content-Type'      => 'application/xml',
        'Content-Length'    => request_body.length.to_s,
        'QUICKBASE-ACTION'  => "API_#{api_call}"
      }
    end

    def build_request_url( api_call, db_id=nil )
      url = base_url

      # Different calls have different API paths. Assign those here
      case api_call
      when :authenticate
        url += '/db/main'
      else
        url += "/db/#{db_id}"
      end
    end

    def base_url
      "https://#{base_domain}"
    end

    def base_domain
      "#{@domain}.quickbase.com"
    end

    def build_request_xml( tags )
      xml = '<qdbapi>'
      xml += tags.map{ |name, value| "<#{name}>#{value}</#{name}>" }.join()
      xml += ticket_and_token
      xml += '</qdbapi>'
    end

    def build_update_xml( new_values, record_id=nil )
      xml = '<qdbapi>'
      if record_id
        xml += "<key>#{record_id}</key>"
      end

      new_values = new_values.map do |field_id, value|
        # Values that are hashes with name and file are encoded seperately
        if value.is_a?( Hash ) && value.length == 2 && value[:name] && value[:file]
          file = encode_file( value[:file] )
          "<field fid='#{field_id}' filename='#{value[:name]}'>#{file}</field>"
        else
          "<field fid='#{field_id}'>#{value.to_s.encode(xml: :text)}</field>"
        end
      end

      xml += new_values.join()
      xml += ticket_and_token
      xml += '</qdbapi>'
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

    def build_csv_xml( new_values, fields_to_import )
      csv_data = []
      new_values.each do |line|
        if line.is_a?( Array )
          csv_data << CSV.generate_line( line )
        elsif line.is_a?( Hash )
          csv_data << CSV.generate_line( line.map{ |k, v| v } )
        end
      end

      xml = '<qdbapi>'
      xml += "<records_csv><![CDATA[\n"
      xml += csv_data.join()
      xml += "]]></records_csv>"
      xml += "<clist>#{fields_to_import}</clist>"
      xml += ticket_and_token
      xml += '</qdbapi>'
    end

    def ticket_and_token
      "<ticket>#{@ticket}</ticket>" +
      "<apptoken>#{@app_token}</apptoken>"
    end

    def parse_xml( xml )
      Nokogiri::HTML( xml )
    end

    def get_tag_value( xml, tag_name )
      tag = xml.css( tag_name.to_s )

      tag_value = nil
      if !tag.empty?
        tag_value = tag[ 0 ].text
      end

      tag_value
    end

    def get_attr_value(tag, attr_name)
      attr_value = tag.attribute(attr_name.to_s).to_s
    end

    def send_quickbase_ui_action(url, parameters={})
      url = URI.parse(url)
      request = Net::HTTP::Post.new(url.request_uri)
      request.set_form_data({'ticket' => @ticket }.merge(parameters))
      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = true

      response = http.request(request)
    end

    def send_request( api_call, db_id, request_data, request_xml=nil )
      # Format request data hash into xml
      if request_data && !request_xml
        request_xml = build_request_xml( request_data )
      end

      url = build_request_url( api_call, db_id )
      headers = build_request_headers( api_call, request_xml )
      result = @http.post( url, request_xml, headers )

      xml_result = parse_xml( result.body )

      error_code = get_tag_value( xml_result, :errcode )
      if error_code.to_i != 0
        error_name = get_tag_value( xml_result, :errtext )
        error_details = get_tag_value( xml_result, :errdetail )
        raise "\nAPI ERROR ##{error_code}: #{error_name}\n#{error_details}"
      end

      xml_result
    end
  end
end
