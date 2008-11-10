class RemoveEndpointFromSoapOperations < ActiveRecord::Migration
  def self.up
    remove_column :soap_operations, :endpoint
  end

  def self.down
    add_column :soap_operations, :endpoint, :string
  end
end
