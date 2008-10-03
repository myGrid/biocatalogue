
require 'open-uri'
require 'rexml/document'
require 'lib/biocat_wsdl_parser'
require 'lib/acts_as_service_versionified'


class SoapService < ActiveRecord::Base
  include BiocatWSDL
  before_create :check_duplicates, :get_service_attributes
  
  acts_as_service_versionified
  
  has_many :soap_operations, :dependent => :destroy
  has_many :annotations, :as => :annotatable
  
  validates_presence_of :name
  validates_presence_of :description
  validates_presence_of :wsdl_location
  #validates_uniqueness_of :wsdl_location
  validates_associated :soap_operations
  
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
  protected
  #------------------------------------------------
  # get the service attributes from a wsdl url
  # supplied in the web form
  #
  def get_service_attributes
    wsdl_url = self.wsdl_location  #set at instantiation
    wsdl_file = open(wsdl_url.strip()).read
    doc       = Document.new(wsdl_file)
    root      = doc.root
    operation_attributes = get_operation_attributes(root)
    message_attributes   = get_message_attributes(root)
    service_attributes   = format_service_attributes(operation_attributes,
                                                        message_attributes)
    name_and_desc        = get_name_and_description(root)
    self.name            = name_and_desc['name']
    self.description     = name_and_desc['description']
    self.new_service_attributes = service_attributes
    #return service_attributes
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
