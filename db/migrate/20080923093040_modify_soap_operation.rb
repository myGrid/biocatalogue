class ModifySoapOperation < ActiveRecord::Migration
  def self.up
    add_column :soap_operations, :parameterOrder, :string
  end

  def self.down
    remove_column :soap_operations, :parameterOrder
  end
end
