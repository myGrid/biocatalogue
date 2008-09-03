class CreateSoapServices < ActiveRecord::Migration
  def self.up
    create_table :soap_services do |t|
      t.string :name
      t.string :wsdl_location
      t.text :description
      t.binary :wsdl_file
      t.string :version
      t.integer :web_service_id
      t.integer :provider_id
      t.string :documentation_url

      t.timestamps
    end
  end

  def self.down
    drop_table :soap_services
  end
end
