class AddParentPortTypeToSoapOperations < ActiveRecord::Migration
  def self.up
    add_column :soap_operations, :parent_port_type, :string
  end

  def self.down
    remove_column :soap_operations, :parent_port_type
  end
end
