
#require 'open-uri'
require 'rexml/document'
require 'active_support/inflector'

include REXML
  

module BiocatWSDL
  
  # This method extracts the service operations from a
  # wsdl document- The 'operation' tags  handles are those within the portType tags
  #
  # An operation, its inputs and outputs are extracted into
  # an array of hashes
  # Example :
  #
  def get_operation_attributes(root)
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
  
  def get_message_attributes(root)
    prefix = ""
    prefix="wsdl:" if root.elements["wsdl:message"]
    my_message_attributes = [] 
    
    root.each_element("//#{prefix}message"){|message| 
      my_message = {}
      my_parts =[]
  
      my_message["the_message"] = get_hash(message.attributes) 
      if message.elements["#{prefix}part"]
        message.elements.each{ |part|
        my_parts << get_hash(part.attributes) 
      }
      end
      my_message["the_parts"]= my_parts
      my_message_attributes << my_message
      }
    return my_message_attributes
  end
  
  def get_message(the_messages, name)
    the_messages.each{ |m|
       if m["the_message"]["name"] == name
          return m
       end
    }
    return {}
  end
  
  def modify_type_field_name(param_type, data)
    data.each{ |d| 
     if d.has_key?("type")
       val = d["type"]
       d[param_type+"_type"] = val
       d.delete("type")
     elsif d.has_key?("element")
       val = d["element"]
       d[param_type+"_type"] = val
       d.delete("element")
     end
     }
     return data
  end
  
  def get_hash(attr)
    h = {}
    attr.each{|k, v| h[ActiveSupport::Inflector.underscore(k)]=v}
    return h
  end
  
  def get_name_and_description(root)
   
    prefix = ""
    prefix="wsdl:" if root.elements["wsdl:message"]
    
    my_service_attributes ={}
   
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
  
  
end
