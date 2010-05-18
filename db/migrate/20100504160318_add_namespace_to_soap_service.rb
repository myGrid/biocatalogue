class AddNamespaceToSoapService < ActiveRecord::Migration
  def self.up
    add_column :soap_services, :namespace, :string
  end

  def self.down
    remove_column :soap_services, :namespace
  end
end
