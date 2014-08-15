require 'net/https'

module AdvantageQuickbase
  class Connection

    attr_reader :http

    def initialize( domain, username, password, app_token=nil, ticket=nil)
      @domain = domain
      @app_token = app_token if app_token

      # Authenticate with username/password
      if username && password
        data = {
          username: username,
          password: password,
          apptoken: app_token
        }
      else # Authenticate with existing ticket
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

    # Used to send all standard API calls to Quickbase
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

    # Send Non-API calls to quickbase
    def send_quickbase_ui_action( url, parameters={} )
      url = URI.parse(url)

      # Create the POST object for Quickbase
      request = Net::HTTP::Post.new(url.request_uri)
      request.set_form_data({'ticket' => @ticket }.merge(parameters))

      # Send the HTTP request
      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = true

      response = http.request( request )
    end

    # Request Headers for all QB API calls
    def build_request_headers( api_call, request_body )
      {
        'Content-Type'      => 'application/xml',
        'Content-Length'    => request_body.length.to_s,
        'QUICKBASE-ACTION'  => "API_#{api_call}"
      }
    end

    # Build the XMl for a a request
    def build_request_xml( tags )
      xml = '<qdbapi>'
      xml += tags.map{ |name, value| "<#{name}>#{value}</#{name}>" }.join()
      xml += ticket_and_token
      xml += '</qdbapi>'
    end

    # Build the XML for an Add/Update request
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


    # Build the XML request for CSV calls
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

    def ticket_and_token
      "<ticket>#{@ticket}</ticket>" +
      "<apptoken>#{@app_token}</apptoken>"
    end
  end
end
