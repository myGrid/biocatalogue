class RenameSoapOperationPortId < ActiveRecord::Migration
  def self.up
    rename_column :soap_operations, :port_id, :soap_service_port_id
  end

  def self.down
    rename_column :soap_operations, :soap_service_port_id, :port_id
  end
end
