class ModifySoapOperations < ActiveRecord::Migration
  def self.up
    rename_column :soap_operations, :parameterOrder, :parameter_order
  end

  def self.down
    rename_column :soap_operations, :parameter_order, :parameterOrder
  end
end
