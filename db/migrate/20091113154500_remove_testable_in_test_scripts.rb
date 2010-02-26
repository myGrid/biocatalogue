class RemoveTestableInTestScripts < ActiveRecord::Migration
  def self.up
    remove_column :test_scripts, :testable_id
    remove_column :test_scripts, :testable_type
  end

  def self.down
    add_column :test_scripts, :testable_id, :integer, :null => false
    add_column :test_scripts, :testable_type, :string, :null => false
  end
end
