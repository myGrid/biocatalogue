class ModifySoapOperation < ActiveRecord::Migration
  def self.up
    add_column :soap_operations, :parameterOrder, :string
  end

  def self.down
    drop_column :soap_operations, :parameterOrder
  end
end
