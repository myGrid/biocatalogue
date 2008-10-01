class ModifySoapInputs < ActiveRecord::Migration
  def self.up
    add_column :soap_inputs, :input_type, :string
  end

  def self.down
    remove_column :soap_inputs, :input_type
  end
end
