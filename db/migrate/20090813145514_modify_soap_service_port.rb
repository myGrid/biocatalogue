class ModifySoapServicePort < ActiveRecord::Migration
  def self.up
    add_column :soap_service_ports, :soap_service_id, :integer
  end

  def self.down
    remove_column :soap_service_ports, :soap_service_id
  end
end
