class CreateWsdlFiles < ActiveRecord::Migration
  def self.up
    create_table :wsdl_files do |t|
      t.string :location
      t.integer :content_blob_id
      
      t.timestamps
    end
    
    # Update the soap_services records to make sure to point to new 
    # wsdl_files and not to the content_blobs directly
    SoapService.transaction do
      SoapService.record_timestamps = false
      SoapService.all.each do |s|
        c_blob = ContentBlob.find_by_id(s.wsdl_file_id)
        if c_blob
          w = WsdlFile.create(:location => s.wsdl_location, :content_blob_id => c_blob.id, :created_at => s.created_at, :updated_at => s.created_at)
          s.wsdl_file_id = w.id
          s.save!
        end
      end
      SoapService.record_timestamps = true
    end
  end

  def self.down
    # Revert the content_blobs to soap_services connection
    SoapService.transaction do
      SoapService.record_timestamps = false
      SoapService.all.each do |s|
        w = WsdlFile.find_by_id(s.wsdl_file_id)
        c_blob = ContentBlob.find_by_id(w.content_blob_id)
        if w && c_blob
          s.wsdl_file_id = c_blob.id
          s.save!
          w.destroy
        end
      end
      SoapService.record_timestamps = true
    end
    
    drop_table :wsdl_files
  end
end
