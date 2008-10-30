require 'open-uri'
require 'rexml/document'
require 'active_support/inflector'

include REXML

module BioCatalogue
  module WsdlParser
    
    # This method takes a URL to a WSDL file and returns back the following array:
    # [ service_info, error_messages, wsdl_file_contents ]
    # 
    # where:
    # - service_info: the information about the service in a structured, hierarchical form (see below). This is an empty hash if breaking errors occurred.
    # - error_messages: collection (array) of error messages that may have been raised during parsing (these can include breaking or non-breaking errors).
    # - wsdl_file_contents: the contents of the actual WSDL file. This is nil if the WSDL could not be fetched.
    #
    # service_info structure:
    #   { 
    #     :name         => "service_name",
    #     :description  => "service_description",
    #     :operations   => 
    #         [
    #         { 
    #           :name         => "op_name", 
    #           :description  => "op_description",
    #           :inputs       => 
    #               [
    #               { 
    #                 :name         => "input_name",
    #                 :input_type   => "input_type" 
    #               },
    #               { ... } 
    #               ]
    #           :outputs      => 
    #               [
    #               { 
    #                 :name         => "output_name",
    #                 :output_type  => "output_type" 
    #               },
    #               { ... }
    #               ] 
    #         },
    #         { ... } 
    #         ] 
    #   }
    #
    def WsdlParser.parse(wsdl_url)
      service_info = { }
      error_messages =  [ ]
      wsdl_file_contents = nil
      
      begin
        wsdl_file_contents  = open(wsdl_url.strip()).read
        doc                 = Document.new(wsdl_file_contents)
        root                = doc.root
        
        if root.nil?
          error_messages << "The WSDL file could not be parsed. It may be invalid."
        end
        
      rescue Exception => ex
        error_messages << "There was a problem loading the WSDL file - #{ex.message}."
      end
      
      if error_messages.empty?
        root_metadata = get_root_metadata(root)
        
        service_info["name"]        = root_metadata["name"]
        service_info["description"] = root_metadata["description"]
        
        service_info["operations"]  = [ ]
        
        operation_attributes = get_operation_attributes(root)
        message_attributes   = get_message_attributes(root)
        service_attributes   = format_service_attributes(operation_attributes, message_attributes)
        
        service_attributes.each do |op|
          op_hash = { }
          
          op_hash["name"]           = op["operation"]["name"]
          op_hash["description"]    = op["operation"]["description"]
          op_hash["parameter_order"]= op["operation"]["parameter_order"]
          op_hash["inputs"]         = op["inputs"]
          op_hash["outputs"]        = op["outputs"]
          
          service_info["operations"] << op_hash
        end
      end
      
      return [ service_info, error_messages, wsdl_file_contents ]
    end
    
    protected
    
    def WsdlParser.get_root_metadata(root)
     
      prefix = ""
      prefix="wsdl:" if root.elements["wsdl:message"]
      
      my_service_attributes = {}
     
      root.each_element("//#{prefix}service"){|service|
      my_service_attributes = get_hash(service.attributes)
      if service.elements["#{prefix}documentation"]
        my_service_attributes["description"] = service.elements["#{prefix}documentation"].text
      end
      }
      if root.elements["#{prefix}documentation"]
        my_service_attributes["description"] = root.elements["#{prefix}documentation"].text
      end
      
      return my_service_attributes
     
    end
    
    # This method extracts the service operations from a
    # wsdl document- The 'operation' tags  handles are those within the portType tags
    #
    # An operation, its inputs and outputs are extracted into
    # an array of hashes
    # Example :
    #
    def WsdlParser.get_operation_attributes(root)
      prefix = ""
      prefix="wsdl:" if root.elements["wsdl:message"]
      my_operation_attributes = []
      
      root.each_element("//#{prefix}portType/#{prefix}operation"){|operation| 
      details = {}
      details["operation"] = get_hash(operation.attributes)
      if operation.elements["#{prefix}input"]
        details['inputs'] = get_hash(operation.elements["#{prefix}input"].attributes)
      end
      if operation.elements["#{prefix}output"]
        details['outputs'] = get_hash(operation.elements["#{prefix}output"].attributes)
      end
      if operation.elements["#{prefix}documentation"]
        details['operation']["description"] = operation.elements["#{prefix}documentation"].text
      end
      my_operation_attributes << details
      }
      return my_operation_attributes
    end
    
    def WsdlParser.get_message_attributes(root)
      prefix = ""
      prefix="wsdl:" if root.elements["wsdl:message"]
      my_message_attributes = [] 
      
      root.each_element("//#{prefix}message"){|message| 
        my_message = {"description" => ""}
        my_parts =[]
    
        my_message["the_message"] = get_hash(message.attributes) 
        if message.elements["#{prefix}part"]
          message.elements.each("#{prefix}part"){ |part|
          my_parts << get_hash(part.attributes) 
           }
        end
       if message.elements["#{prefix}documentation"]
         my_message["description"] = message.elements["#{prefix}documentation"].text
       end
        my_message["the_parts"]= my_parts
        my_message_attributes << my_message
        }
      return my_message_attributes
    end
    
    #--------------------------------------------------------------------
    # helper functions to structure the data so that
    # it can be transactionally saved to the database
    
    def WsdlParser.format_service_attributes(the_operations, the_messages)
      
      the_operations.each do |operation|
        operation["inputs"] = get_message(the_messages,
                                    operation["inputs"]["message"].split(':')[1])["the_parts"]
        operation["inputs"] = modify_type_field_name("input", operation["inputs"])                           
        operation["outputs"] = get_message(the_messages,
                                    operation["outputs"]["message"].split(':')[1])["the_parts"]
        operation["outputs"] = modify_type_field_name("output", operation["outputs"])                            
      end
      errors.add_to_base("Service should have at least one operation, got none!") if the_operations.empty?
      return the_operations
    end
    
    def WsdlParser.get_message(the_messages, name)
      the_messages.each{ |m|
         if m["the_message"]["name"] == name
            return m
         end
      }
      return {}
    end
    
    def WsdlParser.modify_type_field_name(param_type, data)
      if ["input", "output"].include?(param_type.downcase)
        data.each{ |d| 
          if d.has_key?("type")
            val = d["type"]
            d["computational_type"] = val
            d.delete("type")
          elsif d.has_key?("element")
            val = d["element"]
            d["computational_type"] = val
            d.delete("element")
          end
        }
      end
      return data
    end
    
    def WsdlParser.get_hash(attr)
      h = {}
      attr.each{|k, v| h[ActiveSupport::Inflector.underscore(k)]=v}
      return h
    end
    
  end
end
