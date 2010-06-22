# BioCatalogue: app/models/soap_service.rb
#
# Copyright (c) 2008-2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

class SoapService < ActiveRecord::Base
  
  serialize :description_from_soaplab
  
  if ENABLE_CACHE_MONEY
    is_cached :repository => $cache
    index :name
    index :wsdl_location
  end
  
  if ENABLE_TRASHING
    acts_as_trashable
  end
  
  acts_as_service_versionified  # This also mixes in acts_as_annotatable
  
  has_many :wsdl_files,
           :dependent => :destroy,
           :order => "created_at DESC"
  
  has_many :soap_operations, 
           :dependent => :destroy,
           :include => [ :soap_inputs, :soap_outputs ],
           :conditions => "soap_operations.archived_at IS NULL",
           :order => "soap_operations.name ASC"
  
  has_many :archived_soap_operations,
           :class_name => "SoapOperation",
           :foreign_key => "soap_service_id",
           :dependent => :destroy,
           :include => [ :soap_inputs, :soap_outputs ],
           :conditions => "soap_operations.archived_at IS NOT NULL",
           :order => "soap_operations.name ASC"
  
  has_many :url_monitors, 
           :as => :parent,
           :dependent => :destroy
  
  has_many :soap_service_ports,
           :conditions => "soap_service_ports.archived_at IS NULL",
           :dependent => :destroy
           
  has_many :soap_service_changes,
           :readonly => true,
           :dependent => :destroy,
           :order => "updated_at DESC"
  
  # This is to protect some fields that should
  # only get their data from the WSDL doc.
  attr_protected :name, 
                 :description, 
                 :documentation_url
  
  validates_presence_of :name

  validates_associated :soap_operations, 
                       :soap_service_ports,
                       :wsdl_files
  
  validates_url_format_of :wsdl_location,
                          :allow_nil => false,
                          :message => 'is not valid'
 
  if ENABLE_SEARCH
    acts_as_solr(:fields => [ :name, :namespace, :description, :documentation_url, :wsdl_location, :service_type_name, :description_from_soaplab,
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
        count += 1 unless output.computational_type_details.blank?
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
  # - data - additional metadata that may be useful after the populate process.
  def populate
    success = true
    data = { }
    
    if self.wsdl_location.blank?
      errors.add_to_base("No WSDL Location set for this Soap Service.")
      success = false
    end
    
    if success
      service_info, err_msgs, wsdl_file_contents = BioCatalogue::WsdlParser.parse(self.wsdl_location)
      
      if service_info.blank?
        errors.add_to_base("Failed to parse the WSDL file.")
        success = false
      end
      
      unless err_msgs.empty?
        errors.add_to_base("Error occurred whilst processing the WSDL file. Error(s): #{err_msgs.to_sentence}.")
        success = false
      end
      
      if success
        c_blob = ContentBlob.create(:data => wsdl_file_contents)
        self.wsdl_files << WsdlFile.new(:location => self.wsdl_location, :content_blob_id => c_blob.id)
        
        self.name         = service_info['name']
        self.description  = service_info['description']
        
        self.build_soap_service_ports(service_info, build_soap_objects(service_info))
        
        data["endpoint"] = service_info["endpoint"]
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
  
  def latest_wsdl_contents
    self.wsdl_files.first.content_blob.data
  end
  
  # This checks to see if the SOAP service has changed (i.e.: the WSDL has been updated or more info could be parsed) and
  # then carries out any relevant additions/updates/deletions to the SoapService model and it's constituents (including metadata). 
  # If any changes are detected, an appropriate SoapServiceChange changelog entry is created, together with an ActivityLog entry to say 
  # that a SOAP service has been updated.
  #
  # NOTE: We need to take into account WSDLs that were parsed by the old WSDL parser and therefore don't have port information etc.
  #       I.e.: the current model state might be out of sync with even the last cached WSDL.
  #       This method will just take the latest wsdl info and manually sync the current model state. Thus it will treat all changes 
  #       in the same way and create one SoapServiceChange entry.
  #
  # Returns an Array with the following:
  #   success - a Boolean value to indicate whether this method was successfully run or not.
  #   update_found - a Boolean value to determine whether an update was found to the WSDL.
  #   changelog - the relevant SoapServiceChange object generated (if a change was detected, otherwise nil). 
  def update_from_latest_wsdl!
    success = true
    update_found = false
    changes = SoapServiceChange.new(:soap_service_id => self.id)
    
    begin
      transaction do
        new_info, err_msgs, wsdl_file_contents = BioCatalogue::WsdlParser.parse(self.wsdl_location)
        
        if new_info.blank? or !err_msgs.empty?
          success = false
        else
          
          # Name
          if self.name != new_info['name']
            update_found = true
            changes.add_entry("The name of the SOAP service has been updated from '#{self.name}' to '#{new_info['name']}'.")
            self.name = new_info['name']
            
            # Update the parent Service too
            service = self.service
            service.name = new_info['name']
            service.save!
          end
          
          # Description
          if self.description != new_info['description']
            update_found = true
            changes.add_entry("The description of the SOAP service has been updated")
            self.description = new_info['description']
          end
          
          # Namespace
          if self.namespace != new_info['namespace']
            update_found = true
            changes.add_entry("The namespace of the SOAP service has been updated from '#{self.namespace}' to '#{new_info['namespace']}'.")
            self.namespace = new_info['namespace']
          end
          
          # Endpoint
          #
          # If endpoint doesn't match an existing one, then...
          # If 1 ServiceDeployment then update, else create new ServiceDeployment.
          new_endpoint = new_info['endpoint']
          endpoint_exists = false
          self.service_deployments.each { |s| endpoint_exists = true if s.endpoint == new_endpoint }
          unless endpoint_exists
            update_found = true
            
            if self.service_deployments.length == 1
              s_d = self.service_deployments.first
              changes.add_entry("The service's endpoint (base URL) has been updated from '#{s_d.endpoint}' to '#{new_endpoint}'")
              s_d.endpoint = new_endpoint
              s_d.save!
            else
              ServiceDeployment.create!(:service_id => self.service.id, :service_version_id => self.service_version.id, :endpoint => new_endpoint)
              
              changes.add_entry("The service's endpoint (base URL) has changed (to: '#{new_endpoint}') and a new service deployment has been added to this service.")
            end
          end
          
          # Now go through the Ports and Operations in the new service info 
          # and update/create as appropriate. Log which ones were found in the db,
          # then go through the current ones in the db and delete any that were not 
          # originally found or created.
          
          # Ports
          
          # If there are no ports in the new service info then ignore.
          unless new_info['ports'].blank?
            found_or_created_port_ids = [ ]
            
            new_info['ports'].each do |port|
              existing_ports = self.soap_service_ports.find_all_by_name(port['name'])
              
              existing_port = if existing_ports.empty?
                nil
              elsif existing_ports.length == 1
                existing_ports.first
              else
                BioCatalogue::Util.warn("Multiple SoapServicePort objects with the same name ('#{port['name']}') were found for SoapService (ID: #{self.id}). So only taking the first one.")
                existing_ports.first
              end
              
              if existing_port.nil?
                # Create a new SoapServicePort for this SoapService
                update_found = true
                new_soap_service_port = SoapServicePort.create!(port.merge(:soap_service_id => self.id))
                changes.add_entry("A new port called '#{port['name']}' was found.")
                found_or_created_port_ids << new_soap_service_port.id
              else
                # Go through and check for updates in the existing SoapServicePort
                
                found_or_created_port_ids << existing_port.id
                
                existing_port_updated = false
                
                # Protocol, style, location
                %w( protocol style location ).each do |f|
                  if existing_port[f] != port[f]
                    update_found = true
                    changes.add_entry("The #{f} for the port '#{port['name']}' has changed from '#{existing_port[f]}' to '#{port[f]}'.")
                    existing_port[f] = port[f]
                    existing_port_updated = true
                  end
                end
                
                existing_port.save! if existing_port_updated
              end
            end
            
            # Delete any ports that were not in the new info
            self.soap_service_ports(true).each do |port|
              unless found_or_created_port_ids.include?(port.id)
                update_found = true
                port.archive!
                changes.add_entry("The port '#{port.name}' has been removed from the WSDL (and thus archived in the BioCatalogue).")
              end
            end
          
          end
          
          # Operations
          
          unless new_info['operations'].blank?
            found_or_created_operation_ids = [ ]
            
            new_info['operations'].each do |operation|
              existing_ops = self.soap_operations.find(:all, :conditions => { :name => operation['name'], :parent_port_type => operation['parent_port_type'] })
              
              # If empty, try again but this time with no port information
              if existing_ops.empty?
                existing_ops = self.soap_operations.find(:all, :conditions => { :name => operation['name'], :parent_port_type => nil })
              end
              
              # If empty still, then ignore any port info, BUT only if service has no port info or only one port
              if existing_ops.empty? and (new_info['ports'].blank? or new_info['ports'].length == 1)
                existing_ops = self.soap_operations.find(:all, :conditions => { :name => operation['name'] })
              end
              
              existing_op = if existing_ops.empty?
                nil
              elsif existing_ops.length == 1
                existing_ops.first
              else
                BioCatalogue::Util.warn("Multiple SoapOperation objects with the same name ('#{operation['name']}') were found for SoapService (ID: #{self.id}). So only taking the first one.")
                existing_ops.first
              end
              
              if existing_op.nil?
                # Create a new SoapOperation for this SoapService
                
                update_found = true
                
                op_attributes = { :name => operation["name"],
                                  :description => operation["description"],
                                  :parameter_order => operation["parameter_order"],
                                  :parent_port_type => operation["parent_port_type"]}
                        
                new_soap_operation = self.soap_operations.build(op_attributes)
                
                inputs = operation["inputs"]
                outputs = operation["outputs"]
                
                inputs.each do |input_attributes|
                  new_soap_operation.soap_inputs.build(input_attributes)
                end
                
                outputs.each do |output_attributes|
                  new_soap_operation.soap_outputs.build(output_attributes)
                end
                
                unless operation['parent_port_type'].blank?
                  existing_port = self.soap_service_ports.find_by_name(operation['parent_port_type'])
                  new_soap_operation.parent_port_type = operation['parent_port_type']
                  new_soap_operation.soap_service_port = existing_port
                end
                
                new_soap_operation.save!
                
                changes.add_entry("A new operation called '#{operation['name']}' was found. Inputs: #{new_soap_operation.soap_inputs.length}. Outputs: #{new_soap_operation.soap_outputs.length}.")
                
                found_or_created_operation_ids << new_soap_operation.id
              else
                # Go through and check for updates in the existing SoapOperation
                
                found_or_created_operation_ids << existing_op.id
                
                existing_op_updated = false
                
                # Description                
                if existing_op.description != operation['description']
                  update_found = true
                  changes.add_entry("The description for the operation '#{operation['name']}' has been updated.")
                  existing_op.description = operation['description']
                  existing_op_updated = true
                end
                
                # Parameter Order
                unless operation['parameter_order'].blank?
                  if existing_op.parameter_order != operation['parameter_order']
                    update_found = true
                    changes.add_entry("The parameter order for the operation '#{operation['name']}' has changed from '#{existing_op.parameter_order}' to '#{operation['parameter_order']}'.")
                    existing_op.parameter_order = operation['parameter_order']
                    existing_op_updated = true
                  end
                end
                
                # Check the port
                if operation['parent_port_type'].blank?
                  update_found = true
                  changes.add_entry("The parent port type for the operation '#{operation['name']}' has been removed.")
                  existing_op.parent_port_type = operation['parent_port_type']
                  existing_op_updated = true
                else
                  if existing_op.soap_service_port.nil?
                    if (existing_port = self.soap_service_ports.find_by_name(operation['parent_port_type'])).nil?
                      if existing_op.parent_port_type != operation['parent_port_type']
                        update_found = true
                        changes.add_entry("The parent port type for the operation '#{operation['name']}' has been updated from '#{existing_op.parent_port_type}' to '#{operation['parent_port_type']}'.")
                        existing_op.parent_port_type = operation['parent_port_type']
                        existing_op_updated = true
                      end
                    else
                      update_found = true
                      existing_op.parent_port_type = operation['parent_port_type']
                      existing_op.soap_service_port = existing_port
                      changes.add_entry("The parent port for the operation '#{operation['name']}' has been updated to '#{operation['parent_port_type']}'.")
                      existing_op_updated = true
                    end
                  else
                    if existing_op.parent_port_type != operation['parent_port_type'] or existing_op.soap_service_port.name != operation['parent_port_type']
                      new_port = self.soap_service_ports.find_by_name(operation['parent_port_type'])
                      if new_port.nil?
                        BioCatalogue::Util.warn("No SoapServicePort exists for '#{operation['parent_port_type']}' for SoapOperation ID: #{existing_op.id}. It's possible that the WSDL Parser couldn't pick it up.")
                        update_found = true
                        changes.add_entry("The parent port type for the operation '#{operation['name']}' has been updated from '#{existing_op.parent_port_type}' to '#{operation['parent_port_type']}'.")
                        existing_op.parent_port_type = operation['parent_port_type']
                        existing_op_updated = true
                      else
                        update_found = true
                        changes.add_entry("The parent port for the operation '#{operation['name']}' has been updated from '#{existing_op.parent_port_type}' to '#{operation['parent_port_type']}'.")
                        existing_op.parent_port_type = operation['parent_port_type']
                        existing_op.soap_service_port = new_port
                        existing_op_updated = true
                      end
                    end
                  end
                end
                
                # Inputs and Outputs
                found_or_created_node_ids = Hash.new { |h,k| h[k] = [ ] }
                %w(input output).each do |node_type|
                  unless operation[node_type.pluralize].blank?
                    operation[node_type.pluralize].each do |node|
                      existing_node = eval("existing_op.soap_#{node_type.pluralize}.find_by_name(node['name'])")
                      if existing_node.nil?
                        # Create it
                        update_found = true
                        new_node = eval("Soap#{node_type.capitalize}.create!(node.merge(:soap_operation_id => existing_op.id))")
                        changes.add_entry("A new #{node_type} called '#{node['name']}' for operation '#{existing_op.name}' was found.")
                        
                        found_or_created_node_ids[node_type] << new_node.id
                      else
                        # Update it
                        
                        existing_node_updated = false
                        
                        # computational_type, min_occurs, max_occurs
                        %w( computational_type, min_occurs, max_occurs ).each do |f|
                          if existing_node[f] != node[f]
                            update_found = true
                            changes.add_entry("The #{f.gsub('_', ' ')} for the #{node_type} '#{node['name']}' for operation '#{existing_op.name}' has changed from '#{existing_node[f]}' to '#{node[f]}'.")
                            existing_node[f] = node[f]
                            existing_node_updated = true
                          end
                        end
                        
                        # Description                
                        if existing_node.description != node['description']
                          update_found = true
                          changes.add_entry("The description for the #{node_type} '#{node['name']}' for operation '#{existing_op.name}' has been updated.")
                          existing_node.description = node['description']
                          existing_node_updated = true
                        end
                        
                        # computational_type_details
                        if node.has_key?('computational_type_details')
                          if node['computational_type_details'].empty?
                            update_found = true
                            changes.add_entry("The computational type details for the #{node_type} '#{node['name']}' for operation '#{existing_op.name}' has been removed.")
                            existing_node.computational_type_details = node['computational_type_details']
                            existing_node_updated = true
                          else
                            if existing_node.computational_type_details != node['computational_type_details']
                              update_found = true
                              changes.add_entry("The computational type details for the #{node_type} '#{node['name']}' for operation '#{existing_op.name}' has been updated.")
                              existing_node.computational_type_details = node['computational_type_details']
                              existing_node_updated = true
                            end
                          end
                        end
                        
                        existing_node.save! if existing_node_updated
                        
                        found_or_created_node_ids[node_type] << existing_node.id
                      end
                    end
                    
                    current_nodes = eval("existing_op.soap_#{node_type.pluralize}(true)")
                    current_nodes.each do |node|
                      unless found_or_created_node_ids[node_type].include?(node.id)
                        update_found = true
                        node.archive!
                        changes.add_entry("The #{node_type} '#{node.name}' for the operation '#{existing_op.name}' has been removed from the WSDL (and thus archived in the BioCatalogue).")
                      end
                    end
                  end
                end
              
                existing_op.save! if existing_op_updated
              end
            end
            
            # Delete any operations that were not in the new info
            self.soap_operations(true).each do |operation|
              unless found_or_created_operation_ids.include?(operation.id)
                update_found = true
                operation.archive!
                changes.add_entry("The operation '#{operation.name}' (on port '#{operation.parent_port_type}') has been removed from the WSDL (and thus archived in the BioCatalogue).")
              end
            end
          end
          
          if success and update_found
            # Store new WSDL file
            c_blob = ContentBlob.create(:data => wsdl_file_contents)
            self.wsdl_files << WsdlFile.new(:location => self.wsdl_location, :content_blob_id => c_blob.id)
            
            # Update timestamp on SoapService to indicate that it has been updated.
            # This save will also cause it to save it's attributes, if updated.
            self.updated_at = Time.now
            self.save!
            
            # Save the changelog
            changes.save!
          end
          
        end
      end
    rescue Exception => ex
      BioCatalogue::Util.log_exception(ex, :error, "Failed to run 'update_from_latest_wsdl!' for SoapService (ID: #{self.id})")
      success = false
      update_found = false
    end
    
    return [ success, update_found, (update_found ? changes : nil) ]    
  end
  
  def update_description_from_soaplab!(is_soaplab=false)
    if self.soaplab_service? || is_soaplab
      desc = nil 
      begin
        SystemTimer.timeout(60.seconds) do
          proxy = SOAP::WSDLDriverFactory.new(self.wsdl_location).create_rpc_driver
        end
        if !proxy.respond_to?('describe')
          logger.debug('Service has no describe operation')
          return
        end
        begin
          desc = proxy.describe 
        rescue Exception => ex
          logger.warn(ex)
          logger.warn("Calling proxy.describe failed. Now trying proxy.describe('')")
          desc = proxy.describe("") 
        end  
        self.description_from_soaplab = Hash.better_from_xml(desc) if (desc && Hash.better_from_xml(desc).is_a?(Hash))
        self.save!
      rescue Exception => ex
        logger.warn("problems updating the description from soaplab")
        logger.warn(ex)
      end
    else
      logger.warn("Not a soaplab service. Nothing done!")
    end
  end
  
  def soaplab_service?
    return true if self.service.soaplab_server
    return false
  end
  
  def endpoint_available?
    self.connect?
  end

  
  protected
  
  def connect?
    begin
      SystemTimer.timeout(60.seconds) do
        proxy = SOAP::WSDLDriverFactory.new(self.wsdl_location).create_rpc_driver
        operations = proxy.methods(false)
        return true if !operations.empty?
      end
    rescue Exception => ex
      logger.warn("Failed to connect to service")
      logger.warn(ex)
      return false
    end
    return false
  end
  
  
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
    if service_info["ports"].nil?
      return []
    end
    built_ports = []
    ports = service_info["ports"]
    ports.each  do |port|
      built_port =  soap_service_ports.build(port)
      p_ops      = built_soap_ops.collect{|op|  op if op.parent_port_type == built_port.name}
      built_port.soap_operations = p_ops.compact
      built_ports << built_port
    end
    return built_ports
  end
  
  def associated_service_id
    BioCatalogue::Mapper.map_compound_id_to_associated_model_object_id(BioCatalogue::Mapper.compound_id_for(self.class.name, self.id), "Service")
  end
  
end
