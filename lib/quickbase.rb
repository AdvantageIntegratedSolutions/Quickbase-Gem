require 'net/https'
require 'nokogiri'
require 'json'
require 'csv'

module AdvantageQuickbase
  class API
    attr_accessor :ticket

    def initialize( domain, username, password, app_token=nil )
      @domain = domain

      data = {
        username: username,
        password: password,
        apptoken: app_token
      }
      request_xml = build_request_xml( data )

      @http = Net::HTTP.new( base_domain, 443 )
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

    def do_query( db_id, options )
      # Define the query format
      if !options[ :fmt ]
        options[ :fmt ] = 'structured'
      end

      # Normalize the field list variables into period-separated strings
      options[ :clist ] = normalize_list( options[:clist] )
      options[ :slist ] = normalize_list( options[:slist] )

      result = send_request( :doQuery, db_id, options )

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
      xml = build_update_xml( new_values )
      result = send_request( :addRecord, db_id, nil, xml )

      get_tag_value( result, :rid )
    end

    def edit_record( db_id, record_id, new_values )
      xml = build_update_xml( new_values, record_id )
      result = send_request( :editRecord, db_id, nil, xml )

      get_tag_value( result, :rid ).to_s == record_id.to_s
    end

    def delete_record( db_id, record_id )
      result = send_request( :deleteRecord, db_id, {rid: record_id} )

      get_tag_value( result, :rid ).to_s == record_id.to_s
    end

    def import_from_csv( db_id, data_array, columns )
      columns = normalize_list( columns )
      xml = build_csv_xml( data_array, columns )

      result = send_request( :importFromCSV, db_id, nil, xml )
      result.css('rid').map{ |xml_node| xml_node.text.to_i }
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
      xml += "<ticket>#{@ticket}</ticket>"
      xml += '</qdbapi>'
    end

    def build_update_xml( new_values, record_id=nil )
      xml = '<qdbapi>'
      if record_id
        xml += "<key>#{record_id}</key>"
      end
      xml += new_values.map { |field_id, value| "<field fid='#{field_id}'>#{value.to_s.encode(xml: :text)}</field>" }.join()
      xml += "<ticket>#{@ticket}</ticket>"
      xml += '</qdbapi>'
    end

    def build_csv_xml( new_values, fields_to_import )
      xml = '<qdbapi>'
      xml += "<records_csv><![CDATA[\n"
      xml += new_values.map{ |line| CSV.generate_line(line) }.join()
      xml += "]]></records_csv>"
      xml += "<clist>#{fields_to_import}</clist>"
      xml += "<ticket>#{@ticket}</ticket>"
      xml += '</qdbapi>'
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

    def send_request( api_call, db_id, request_data, request_xml=nil )
      # Format request data hash into xml
      if request_data && !request_xml
        request_xml = build_request_xml( request_data )
      end

      url = build_request_url( api_call, db_id )
      headers = build_request_headers( api_call, request_xml )

      result = @http.post( url, request_xml, headers )

      parse_xml( result.body )
    end
  end
end