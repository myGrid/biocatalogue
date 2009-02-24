class AddIndexesForSoapserviceSubstructure < ActiveRecord::Migration
  def self.up
    add_index :soap_operations, [ :soap_service_id ]
    
    add_index :soap_inputs, [ :soap_operation_id ]
    
    add_index :soap_outputs, [ :soap_operation_id ]
  end

  def self.down
    remove_index :soap_operations, :column => [ :soap_service_id ]
    
    remove_index :soap_inputs, :column => [ :soap_operation_id ] 
    
    remove_index :soap_outputs, :column => [ :soap_operation_id ]
  end
end
