class CreateSoapServicePorts < ActiveRecord::Migration
  def self.up
    create_table :soap_service_ports do |t|
      t.string :name
      t.string :protocol
      t.string :style
      t.string :location

      t.timestamps
    end
  end

  def self.down
    drop_table :soap_service_ports
  end
end
