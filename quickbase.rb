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

      puts build_request_url( :authenticate )
      puts build_request_headers( :authenticate, request_xml )
    end

    private
    def build_request_headers( api_call, request_body )
      {
        'Content-Type'      => 'application/xml',
        'Content-Length'    => request_body.length,
        'QUICKBASE-ACTION'  => api_call
      }
    end

    def build_request_url( api_call )
      url = "http://#{@domain}.quickbase.com"

      # Different calls have different API paths. Assign those here
      case api_call
      when :authenticate
        url += '/db/main'
      else
      end
    end
  end
end
