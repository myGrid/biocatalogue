class CreateSoapOutputs < ActiveRecord::Migration
  def self.up
    create_table :soap_outputs do |t|
      t.string :name
      t.text :description
      t.integer :soap_operation_id

      t.timestamps
    end
  end

  def self.down
    drop_table :soap_outputs
  end
end
