class AddOccursToSoapInputsAndOutputs < ActiveRecord::Migration
  def self.up
    add_column :soap_inputs, :min_occurs, :integer
    add_column :soap_inputs, :max_occurs, :integer
    
    add_column :soap_outputs, :min_occurs, :integer
    add_column :soap_outputs, :max_occurs, :integer
  end

  def self.down
    remove_column :soap_inputs, :min_occurs
    remove_column :soap_inputs, :max_occurs
    
    remove_column :soap_outputs, :min_occurs
    remove_column :soap_outputs, :max_occurs
  end
end
