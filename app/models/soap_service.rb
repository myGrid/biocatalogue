# BioCatalogue: app/models/soap_service.rb
#
# Copyright (c) 2008, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

require 'acts_as_service_versionified'
require 'wsdl_parser'

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
           :dependent => :destroy,
           :include => [ :soap_inputs, :soap_outputs ]
  
  attr_protected :name, 
                 :description, 
                 :wsdl_file, 
                 :documentation_url
  
  validates_presence_of :name

  validates_associated :soap_operations
  
  validates_url_format_of :wsdl_location,
                          :allow_nil => false,
                          :message => 'is not valid'
   
  if ENABLE_SEARCH
    acts_as_solr(:fields => [ :name, :description, :documentation_url, :service_type_name ],
                 :include => [ :soap_operations ])
  end
  
  if USE_EVENT_LOG
    acts_as_activity_logged(:models => { :referenced => { :model => :service_version } })
  end

  # Populates (but does not save) this soap service with all the relevant data and child soap objects
  # based on the data from the WSDL file.
  #
  # Returns an array with:
  # - 
  def populate
    success = true
    data = { }
    
    if self.wsdl_location.blank?
      errors.add_to_base("No WSDL Location set for this Soap Service.")
      success = false
    end
    
    if success
      service_info, err_msgs, wsdl_file_contents = BioCatalogue::WsdlParser.parse(self.wsdl_location)
      
      unless err_msgs.empty?
        errors.add_to_base("Error occurred whilst processing the WSDL file. Error(s): #{err_msgs.to_sentence}.")
        success = false
      end
      
      if success
        self.wsdl_file = ContentBlob.new(:data => wsdl_file_contents)
        
        self.name         = service_info['name']
        self.description  = service_info['description']
        
        self.build_soap_objects(service_info)
        
        data["endpoint"] = service_info["end_point"]
      end
    end
    
    return [ success, data ]
  end
  
  def service_type_name
    "SOAP"
  end
  
protected

  # This builds the parts of the SOAP service 
  # (ie: it's operations and their inputs and outputs).
  # This can then be saved transactionally.
  def build_soap_objects(service_info)
    soap_ops_built = [ ]
    
    service_info["operations"].each do |op|
      
      op_attributes = { :name => op["name"],
                        :description => op["description"],
                        :parameter_order => op["parameter_order"],
                        :parent_port_type => op["parent_port_type"]}
      inputs = op["inputs"]
      outputs = op["outputs"]
      
      soap_operation = soap_operations.build(op_attributes)
      
      inputs.each do |input_attributes|
        soap_operation.soap_inputs.build(input_attributes)
      end
      
      outputs.each do |output_attributes|
        soap_operation.soap_outputs.build(output_attributes)
      end
      
      soap_ops_built << soap_operation
      
    end
    
    return soap_ops_built
  end
  
end
