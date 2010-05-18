class AddSoaplabDescriptionToSoapService < ActiveRecord::Migration
  def self.up
    add_column :soap_services, :description_from_soaplab, :text
  end

  def self.down
    remove_column :soap_services, :description_from_soaplab
  end
end
