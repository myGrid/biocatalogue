# BioCatalogue: app/models/soap_service.rb
#
# Copyright (c) 2008, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

class SoapService < ActiveRecord::Base
  if ENABLE_CACHE_MONEY
    is_cached :repository => $cache
    index :name
    index :wsdl_location
  end
  
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
  
  has_many :url_monitors, 
           :as => :parent,
           :dependent => :destroy
  
  has_many :soap_service_ports,
            :dependent => :destroy
  
  # This is to protect some fields that should
  # only get their data from the WSDL doc.
  attr_protected :name, 
                 :description, 
                 :wsdl_file, 
                 :documentation_url
  
  validates_presence_of :name

  validates_associated :soap_operations, 
                       :soap_service_ports
  
  validates_url_format_of :wsdl_location,
                          :allow_nil => false,
                          :message => 'is not valid'
   
  if ENABLE_SEARCH
    acts_as_solr(:fields => [ :name, :description, :documentation_url, :wsdl_location, :service_type_name,
                              { :associated_service_id => :r_id } ] )
  end
  
  if USE_EVENT_LOG
    acts_as_activity_logged(:models => { :referenced => { :model => :service_version } })
  end
  
  # ======================================
  # Class level method stubs reimplemented
  # from acts_as_service_versionified
  # --------------------------------------
  
  def self.check_duplicate(wsdl_location, endpoint)
    obj = SoapService.find(:first, :conditions => { :wsdl_location => wsdl_location }) #||
          # commenting the ||  on 10-03-2009
          # ================================
          #  Some wsdls share endpoints though not exposing the same interface.
          #  which makes them appear as duplicates of each other
          # e.g       http://www.cbs.dtu.dk/ws/MaxAlign/MaxAlign_1_1_ws0.wsdl
          #     and   http://www.cbs.dtu.dk/ws/SignalP/SignalP_3_1_ws0.wsdl 
          #ServiceDeployment.find(:first, :conditions => { :endpoint => endpoint })
          
    return (obj.nil? ? nil : obj.service)
  end
  
  # ======================================
  
  
  # =========================================
  # Instance level method stubs reimplemented
  # from acts_as_service_versionified
  # -----------------------------------------
  
  def service_type_name
    "SOAP"
  end
  
  # Note: 'name' fields are not considered "metadata", as these are standard and compulsory.
  def total_db_metadata_fields_count
    count = 0
    
    count += 1 unless self.description.blank?
    count += 1 unless self.documentation_url.blank?
    
    self.soap_operations.each do |op|
      count += 1 unless op.description.blank?
      count += 1 unless op.parameter_order.blank?
      
      op.soap_inputs.each do |input|
        count += 1 unless input.description.blank?
        count += 1 unless input.computational_type.blank?
      end
      
      op.soap_outputs.each do |output|
        count += 1 unless output.description.blank?
        count += 1 unless output.computational_type.blank?
      end
    end
    
    return count
  end
  
  # This method returns a count of all the annotations for this SoapService and its child operations/inputs/outputs.
  def total_annotations_count(source_type)
    count = 0
    
    count += self.count_annotations_by(source_type)
    
    self.soap_operations.each do |op|
      count += op.count_annotations_by(source_type)
      
      op.soap_inputs.each do |input|
        count += input.count_annotations_by(source_type)
      end
      
      op.soap_outputs.each do |output|
        count += output.count_annotations_by(source_type)
      end
    end
    
    return count
  end
  
  # =========================================


  # Populates (but does not save) this soap service with all the relevant data and child soap objects
  # based on the data from the WSDL file.
  #
  # Returns an array with:
  # - success - whether the process of populating the soap service suceeded or not.
  # - data - the hash structure representing the soap service and it's underlying metadata from the WSDL.
  def populate
    success = true
    data = { }
    
    if self.wsdl_location.blank?
      errors.add_to_base("No WSDL Location set for this Soap Service.")
      success = false
    end
    
    if success
      #service_info, err_msgs, wsdl_file_contents = BioCatalogue::WsdlParser.parse(self.wsdl_location)
      service_info, err_msgs, wsdl_file_contents = BioCatalogue::WSDLUtils::WSDLParser.parse(self.wsdl_location)
      
      if service_info.nil?
        errors.add_to_base("Failed to parse the WSDL file.")
        success = false
      end
      
      unless err_msgs.empty?
        errors.add_to_base("Error occurred whilst processing the WSDL file. Error(s): #{err_msgs.to_sentence}.")
        success = false
      end
      
      if success
        self.wsdl_file = ContentBlob.new(:data => wsdl_file_contents)
        
        self.name         = service_info['name']
        self.description  = service_info['description']
        
        #self.build_soap_objects(service_info)
        self.build_soap_service_ports(service_info, build_soap_objects(service_info))
        
        data["endpoint"] = service_info["end_point"]
      end
    end
    
    return [ success, data ]
  end
  
  def submit_service(endpoint, actual_submitter, annotations_data)
    success = true
    
    begin
      transaction do
        self.save!
        self.perform_post_submit(endpoint, actual_submitter)
      end
    rescue Exception => ex
      #ActiveRecord::RecordNotSaved, ActiveRecord::RecordInvalid
      logger.error("Failed to submit SOAP service - #{endpoint}. Exception:")
      logger.error(ex.message)
      logger.error(ex.backtrace.join("\n"))
      success = false
    end  
    
    if success
      begin
        self.process_annotations_data(annotations_data, actual_submitter)
      rescue Exception => ex
        logger.error("Failed to process annotations after SOAP service creation. SOAP service ID: #{self.id}. Exception:")
        logger.error(ex.message)
        logger.error(ex.backtrace.join("\n"))
      end
    end
    
    return success
  end
 
 
  def latest_wsdl_location_status
    result = nil
    
    monitor = UrlMonitor.entry_for(self.class.name, self.id, "wsdl_location")
                              
    unless monitor.nil?
      results = TestResult.results_for(monitor.class.name, monitor.id, 1)
      result = results.first unless results.empty?
    end
    
    return result || TestResult.new_with_unknown_status
  end
  
  def wsdl_location_recent_history
    results = [ ] 
    
    monitor = UrlMonitor.entry_for(self.class.name, self.id, "wsdl_location")
                              
    unless monitor.nil?
      results = TestResult.results_for(monitor.class.name, monitor.id)
    end
    
    return results
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
  
  # build the ports for this service
  # A set of operations are bound to a port
  
  def build_soap_service_ports(service_info, built_soap_ops)
    built_ports = []
    ports = service_info["ports"]
    ports.each  do |port|
      built_port =  soap_service_ports.build(port)
      p_ops      = built_soap_ops.collect{|op|  op if op.parent_port_type == built_port.name}
      built_port.soap_operations = p_ops.compact
      #built_ports << soap_service_ports.build(port)
      built_ports << built_port
    end
    return built_ports
  end
  
  def associated_service_id
    BioCatalogue::Mapper.map_compound_id_to_associated_model_object_id(BioCatalogue::Mapper.compound_id_for(self.class.name, self.id), "Service")
  end
  
end
