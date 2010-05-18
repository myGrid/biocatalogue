class ChangeWsdlFilesToSoapServicesToManyToOne < ActiveRecord::Migration
  def self.up
    add_column :wsdl_files, :soap_service_id, :integer, :null => false
    
    SoapService.record_timestamps = false
    
    SoapService.all.each do |soap_service|
      wsdl_file = WsdlFile.find_by_id(soap_service.wsdl_file_id)
      if wsdl_file
        wsdl_file.soap_service_id = soap_service.id
        wsdl_file.save
      end
    end
    
    SoapService.record_timestamps = true
    
    remove_column :soap_services, :wsdl_file_id
  end

  # Reverting this db migrate script may result in orphaned WsdlFile records
  # (if there were more than one WsdlFiles for any SoapService).
  def self.down
    add_column :soap_services, :wsdl_file_id, :integer, :null => false
    
    SoapService.record_timestamps = false
    
    SoapService.all.each do |soap_service|
      wsdl_file = WsdlFile.find_by_soap_service_id(soap_service.id)
      unless wsdl_file
        soap_service.wsdl_file_id = wsdl_file.id
        soap_service.save
      end
    end
    
    SoapService.record_timestamps = true
    
    remove_column :wsdl_files, :soap_service_id
  end
end
