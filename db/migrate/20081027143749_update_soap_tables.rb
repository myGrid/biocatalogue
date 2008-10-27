class UpdateSoapTables < ActiveRecord::Migration
  def self.up
    remove_column :soap_services, :wsdl_file
    add_column :soap_services, :wsdl_file_id, :integer

    add_column :soap_operations, :endpoint, :string
    
    rename_column :soap_inputs, :input_type, :computational_type
    
    rename_column :soap_outputs, :output_type, :computational_type
  end

  def self.down
    add_column :soap_services, :wsdl_file, :binary
    remove_column :soap_services, :wsdl_file_id
    
    remove_column :soap_operations, :endpoint
    
    rename_column :soap_inputs, :computational_type, :input_type
    
    rename_column :soap_outputs, :computational_type, :output_type 
  end
end
