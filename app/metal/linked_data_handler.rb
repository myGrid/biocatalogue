# BioCatalogue: app/metal/linked_data_handler.rb
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.

# Author: Jits

# This Metal app handles Linked Data compliance for HTTP requests.
# 
# The methodology adopted is the "303 redirect to extension" method -
# i.e.: requests to the non-information resource URI are redirected (via a 303) to 
# the appropriate representation which is essentially at {non-info_resource_URI}.{file_extension},
# where 'file_extension' is the appropriate file extension for the content type requested.
#
# See http://wiki.myexperiment.org/index.php/LinkedData for more info.
#
# Currently, this will only be done IFF:
# - the request is an HTTP GET, and
# - the requested content type is XML, ATOM or JSON.
#
# Caveats with this implementation:
# - Doesn't handle well situations where *multiple* HTTP Accept content types are specified (it will always pick the first one and handle that). 
#   In "proper" scenarios it should be able to select the most appropriate one based on what the system can provide.
# - To check that a specific representation has been accessed, it will check the path info (this doesn't include the host name nor the query parameters)
#   for a dot ('.'). If this is the case it won't do a redirect.

require 'action_controller/mime_type'

class LinkedDataHandler
  def self.call(env)
    output = [ 404, { "Content-Type" => "text/html" }, "Not Found" ]
    
    begin
      
      puts "******"
      
      puts "LinkedDataHandler metal app..."
      puts "Intial URL: #{env['REQUEST_URI']}"
      
      puts Benchmark.measure {
        handler = LinkedDataHandlerApp.new
        output = handler.call(env)
      }
      
      puts "******"
      
    rescue Exception => ex
      puts ex.message
      puts ex.backtrace.join("\n")
    end
    
    return output
  end
  
  class LinkedDataHandlerApp
    
    def allow?(path)
      excludes = [ /^\/$/,
                   /^\/sessions.*/,
                   /rpx/,
                   /^\/register/,
                   /^\/signup/,
                   /^\/login/,
                   /^\/signin/,
                   /^\/activate_account/,
                   /^\/forgot_password/,
                   /^\/request_reset_password/,
                   /^\/reset_password/, ]
      
      excludes.each do |regex|
        return false if regex.match(path)
      end
      
      return true
    end
    
    def call(env)
      # Note: to check that this is a request for a non-information resource, we check that the path doesn't contain the '.' character.
      if env["REQUEST_METHOD"] == "GET" and 
         !env["PATH_INFO"].include?(".") and
         allow?(env["PATH_INFO"])
        
        format = Mime::Type.parse(env["HTTP_ACCEPT"]).first
        
        if [ :xml, :atom, :json, :bljson ].include?(format.to_sym)
          
          url = if env['REQUEST_URI'].include?("?")
            "#{env["rack.url_scheme"]}://#{env['HTTP_HOST']}#{env['REQUEST_URI'].gsub(/(.+)\?(.*)/) { |m| $1 + '.' + format.to_sym.to_s + '?' + $2 }}"
          elsif env['REQUEST_URI'][-1,1] == '/'
            "#{env["rack.url_scheme"]}://#{env['HTTP_HOST']}#{env['REQUEST_URI'].chop}.#{format.to_sym}"
          else
            "#{env["rack.url_scheme"]}://#{env['HTTP_HOST']}#{env['REQUEST_URI']}.#{format.to_sym}"
          end
          
          puts "Linked Data compliance: XML, ATOM, JSON or BLJSON request, so 303'ing to '#{url}'"
          
          return [ 303, { 'Content-Type' => 'text/plain', 'Content-Length' => '0',
                   'Location' => url },
                   [] ]
          
        else
          
          puts "Linked Data compliance: non XML, ATOM, JSON or BLJSON request, so not 303'ing for now..."
          return [ 404, { "Content-Type" => "text/html" }, "Not Found" ]
          
        end
        
      else
        return [ 404, { "Content-Type" => "text/html" }, "Not Found" ]
      end
    end

  end
  
end
