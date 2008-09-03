class CreateSoapInputs < ActiveRecord::Migration
  def self.up
    create_table :soap_inputs do |t|
      t.string :name
      t.text :description
      t.integer :soap_operation_id

      t.timestamps
    end
  end

  def self.down
    drop_table :soap_inputs
  end
end
