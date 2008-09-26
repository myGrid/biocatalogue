class RenameWebServices < ActiveRecord::Migration
  def self.up
    rename_table :web_services, :services
    rename_column :soap_services, :web_service_id, :service_id
  end

  def self.down
    rename_table :services, :web_services
    rename_column :soap_services, :service_id, :web_service_id
  end
end
