require 'soap/wsdlDriver'
require 'open-uri'
require 'rexml/document'

include REXML
  

class SoapService < ActiveRecord::Base
  
  acts_as_service_versionified
  
  before_create :check_duplicates
  
  has_many :soap_operations, :dependent => :destroy
  has_many :annotations, :as => :annotatable
  
  validates_presence_of :name
  validates_presence_of :description
  validates_presence_of :wsdl_location
  #validates_uniqueness_of :wsdl_location
  
  #---------------------------------------------------------
  # this is using the 'virtual attribute' technique  
  # to transactionally save the service and its related
  # operations, inputs and outputs
  def new_service_attributes=(service_attributes)
    service_attributes.each do |attributes|
      op = soap_operations.build(attributes["operation"])
      attributes["inputs"].each do |input_attributes|
        op.soap_inputs.build(input_attributes)
      end
      attributes["outputs"].each do |output_attributes|
        op.soap_outputs.build(output_attributes)
      end
    end
  end
  
  # This function return a fairly complex data structure,
  # which is a list of hashes with nested hashes and lists!!!!
  # The contents of this data structure are the attributes of a 
  # service i.e, the operations, their inputs/outputs and types
  # and embedded documentation on the operations
  #
  # data structure :
  #
  
  def get_service_attributes(wsdl_url)
    wsdl_file = open(wsdl_url.strip()).read
    doc       = Document.new(wsdl_file)
    root      = doc.root
    operation_attributes = get_operation_attributes(root)
    message_attributes   = get_message_attributes(root)
    service_attributes   = format_service_attributes(operation_attributes,
                                                        message_attributes)
    return service_attributes
  end
  
  #-----------------------------------------------------------------------
  # these wsdl parsing functions should be done
  # through standard wsdl api
  #

  # This method extracts the service operations from a
  # wsdl document- The 'operation' tags in the document are
  # expected to be child tags of the 'portType' tag- Attributes
  # of an operation, its inputs and outputs are extracted into
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
  
  #--------------------------------------------------------------------
  # helper functions to structure the data so that
  # it can be transactionally saved to the database
  
  def format_service_attributes(the_operations, the_messages)
    
    the_operations.each do |operation|
      operation["inputs"] = get_message(the_messages,
                                  operation["inputs"]["message"].split(':')[1])["the_parts"]
      operation["inputs"] = modify_type_field_name("input", operation["inputs"])                           
      operation["outputs"] = get_message(the_messages,
                                  operation["outputs"]["message"].split(':')[1])["the_parts"]
      operation["outputs"] = modify_type_field_name("output", operation["outputs"])                            
    end
    return the_operations
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
    attr.each{|k, v| h[k]=v}
    return h
  end
  
  #------------------------------------------------------------------------
  
  protected
  
  def check_duplicates
    wsdls =[] 
    SoapService.find(:all).each{|s| wsdls << s.wsdl_location}
    if wsdls.include?(self.wsdl_location)
      errors.add_to_base("A duplicate for this service exists ")
      return false
    end
    true
  end
  
  
end
