class RemoveColumnsFromSoapServices < ActiveRecord::Migration
  def self.up
    remove_column :soap_services, :service_id
    remove_column :soap_services, :provider_id
    remove_column :soap_services, :version
  end

  def self.down
    add_column :soap_services, :service_id, :integer
    add_column :soap_services, :provider_id, :integer
    add_column :soap_services, :version, :string
  end
end
