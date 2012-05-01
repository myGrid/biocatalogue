#!/usr/bin/ruby
#
# lib/bio_catalogue/wsdl_utils/parser_client.rb
#
# Copyright (c) 2009-2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# A client to the WSDLUtils web service (From EMBRACE registry - www.embraceregistry.net ). 
# This client calls the parse function of the WSDLUtils web service through it REST interface
# and uses the 'lib/wsdl_utils/output_parser.rb' classes to parse the output.


module BioCatalogue
  module WsdlUtils
    module ParserClient
      
      
      # Call the 'parse' method of the
      # WSDLUtils web service. Convert the obtained
      # xml into REXML document. Return the document
      # if all is fine. Otherwise, return nil 
      #
      # Example WSDLUTILS_BASE_URI = 'http://localhost/WSDLUtils/WSDLUtils.php?'
      PARAM_STRING = '?method=parse&wsdl_uri='
      PARSER_URI   = WSDLUTILS_BASE_URI + PARAM_STRING
      
      
      def self.get_parsed_wsdl(wsdl_url)
        wsdl_url = CGI::escape(wsdl_url)
        xml= nil
        begin
          SystemTimer.timeout(20.seconds) do 
            xml = open(PARSER_URI + wsdl_url).read
          end
          doc = REXML::Document.new(xml) unless xml.nil?
        rescue Exception => ex
          Rails.logger.error("Error whilst getting output from WSDLUtils service. Exception: #{ex.class.name} - #{ex.message}")
          Rails.logger.error(ex.backtrace.join("\n"))
          return nil
        end
        return doc || nil
      end
      
      
      
      # get the wsdl from the document. Return the first wsdl only.
      def self.get_wsdl_doc(doc)
        wsdl = nil
        unless doc.nil?
          doc.elements.each('/wsdl') do |wsdl|
            return wsdl
          end
        end
        return wsdl
      end
      
      
      # This method takes a URL to a WSDL file and returns back the following array:
      # [ service_info, error_messages, wsdl_file_contents ]
      #
      # Underneath the method uses the output of the WSDLUtils.parse from EMBRACE wsdl parser developed by Dan Mowbray
      # 
      # where:
      # - service_info: the information about the service in a structured, hierarchical form (see below). This is an empty hash if breaking errors occurred.
      # - error_messages: collection (array) of error messages that may have been raised during parsing (these can include breaking or non-breaking errors).
      # - wsdl_file_contents: the contents of the actual WSDL file. This is nil if the WSDL could not be fetched.
      #
      # service_info structure:
      #   { 
      #     "name"        => "...",
      #     "description" => "...",
      #     "namespace"   => "...",
      #     "endpoint"   => "...",
      #     "ports"       => 
      #       [
      #         {
      #           "name"     => "..."
      #           "protocol" => "..."
      #           "style"    => "style of the communication. Eg document"
      #           "location" => "uri to an endpoint of the service"
      #         } 
      #       ]
      #     "operations"  => 
      #       [
      #         { 
      #           "name"             => "...", 
      #           "description"      => "...",
      #           "action"           => "...",
      #           "parent_port_type" => "port to which operation is bound",
      #           "operation_type"   => "...",
      #           "inputs"           => 
      #             [
      #               { 
      #                 "name"                       => "...",
      #                 "description"                => "...",
      #                 "computational_type"         => "...",
      #                 "computational_type_details" => { ... }
      #
      #               },
      #               { ... } 
      #             ]
      #           "outputs"          => 
      #             [
      #               { 
      #                 "name"                       => "...",
      #                 "description"                => "...",
      #                 "computational_type"         => "...",
      #                 "computational_type_details" => { ... }
      #               },
      #               { ... }
      #             ] 
      #         },
      #         { ... } 
      #       ] 
      #   }
      #
      def self.parse(wsdl)
        error_messages     = []
        service_info       = {}
        wsdl_file_contents = nil
        begin
          SystemTimer.timeout(20.seconds) do
            wsdl_file_contents  = open(wsdl.strip(), :proxy => HTTP_PROXY, "User-Agent" => HTTP_USER_AGENT).read
          end
        
          wsdl_doc = get_wsdl_doc(get_parsed_wsdl(wsdl))
          unless wsdl_doc.nil?
            wsdl_doc.elements.each("service") do |service|
              service_info = BioCatalogue::WsdlUtils::OutputParser::Service.new(service).parse
            end
          end
        rescue Exception => ex
          Rails.logger.error("Error whilst parsing WSDL. Exception: #{ex.class.name} - #{ex.message}")
          Rails.logger.error(ex.backtrace.join("\n"))
            
          error_messages << ex.message
          
          service_info = nil
          wsdl_file_contents = nil
        end
        
        return [service_info, error_messages, wsdl_file_contents ]
      end
      
    end
  end
end




