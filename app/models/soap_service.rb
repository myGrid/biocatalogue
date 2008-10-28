
require 'open-uri'
require 'rexml/document'
require 'acts_as_service_versionified'

class SoapService < ActiveRecord::Base
  acts_as_trashable
  
  acts_as_service_versionified
  
  acts_as_annotatable
  
  belongs_to :wsdl_file,
             :foreign_key => "wsdl_file_id",
             :class_name => "ContentBlob",
             :validate => true,
             :readonly => true,
             :dependent => :destroy
  
  has_many :soap_operations, 
           :dependent => :destroy
  
  attr_protected :name, 
                 :description, 
                 :wsdl_file, 
                 :documentation_url
  
  validates_presence_of :name

  validates_associated :soap_operations
  
  validates_url_format_of :wsdl_location,
                          :allow_nil => false,
                          :message => 'is not valid'
                          
  before_create :check_duplicates, 
                :get_service_attributes
  
  # This function return a fairly complex data structure,
  # which is a list of hashes with nested hashes and lists!!!!
  # The contents of this data structure are the attributes of a 
  # service i.e, the operations, their inputs/outputs and types
  # and embedded documentation on the operations
  #
  # data structure :
  #
  #------------------------------------------------
  # get the service attributes from a wsdl url
  # supplied in the web form
  #
  def get_service_attributes
    wsdl_url = self.wsdl_location  #set at instantiation
    begin
      wsdl_file = open(wsdl_url.strip()).read
      doc       = Document.new(wsdl_file)
      root      = doc.root
      if root == nil 
        raise 
      end
    rescue
      errors.add_to_base("There was a problem reading the WSDL file.")
      return false
    end
    
    
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
  
protected

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
