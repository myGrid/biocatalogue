class AddInterfaceAndDocUrlToRestServices < ActiveRecord::Migration
  def self.up
    add_column :rest_services, :interface_doc_url, :string
    add_column :rest_services, :documentation_url, :string
  end

  def self.down
    remove_column :rest_services, :interface_doc_url
    remove_column :rest_services, :documentation_url
  end
end
