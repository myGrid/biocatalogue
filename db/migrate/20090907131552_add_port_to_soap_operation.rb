class AddPortToSoapOperation < ActiveRecord::Migration
  def self.up
    add_column :soap_operations, :port_id, :integer
  end

  def self.down
    remove_column :soap_operations, :port_id
  end
end
