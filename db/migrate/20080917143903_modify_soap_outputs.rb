class ModifySoapOutputs < ActiveRecord::Migration
  def self.up
    add_column :soap_outputs, :output_type, :string
  end

  def self.down
    remove_column :soap_outputs, :output_type
  end
end
