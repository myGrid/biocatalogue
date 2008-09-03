class CreateSoapOperations < ActiveRecord::Migration
  def self.up
    create_table :soap_operations do |t|
      t.string :name
      t.text :description
      t.integer :soap_service_id

      t.timestamps
    end
  end

  def self.down
    drop_table :soap_operations
  end
end
