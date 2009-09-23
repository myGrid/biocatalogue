class AddInputOutputTypeDetails < ActiveRecord::Migration
  def self.up
    add_column :soap_inputs, :computational_type_details, :text, :limit => 2.megabytes
    add_column :soap_outputs, :computational_type_details, :text, :limit => 2.megabytes
  end

  def self.down
    remove_column :soap_inputs, :computational_type_details
    remove_column :soap_outputs, :computational_type_details
  end
end
