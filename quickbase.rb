require 'net/https'
require 'nokogiri'
require 'json'

module Advantage
  class QuickbaseAPI
    def initialize( domain, username, password, app_token=nil )
      @domain = domain
      @app_token = app_token

      request_xml = "<qdbapi>" +
                      "<username>#{username}</username>" +
                      "<password>#{password}</password>" +
                      "<apptoken>#{app_token}</apptoken>" +
                    "</qdbapi>"

      url = build_request_url( :authenticate )
      headers = build_request_headers( :authenticate, request_xml )

      @http = Net::HTTP.new( base_url, 443 )
      @http.use_ssl = true
      @http.verify_mode = OpenSSL::SSL::VERIFY_NONE

      result = @http.post( url, request_xml, headers )
      parsed_result = Nokogiri::HTML( result.body )

      ticket = parsed_result.css( 'ticket' )
      if !ticket.empty?
        @ticket = ticket.text
      else
        raise "Connection Failed\n\n#{result.body}"
      end
    end

    private
    def build_request_headers( api_call, request_body )
      {
        'Content-Type'      => 'application/xml',
        'Content-Length'    => request_body.length.to_s,
        'QUICKBASE-ACTION'  => "API_#{api_call}"
      }
    end

    def build_request_url( api_call )
      url = base_url

      # Different calls have different API paths. Assign those here
      case api_call
      when :authenticate
        url += '/db/main'
      else
      end
    end

    def base_url
      "https://#{@domain}.quickbase.com"
    end
  end
end
