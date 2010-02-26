class RemoveTestStatusFromTestScripts < ActiveRecord::Migration
  def self.up
    remove_column :test_scripts, :test_status
  end

  def self.down
    add_column :test_scripts, :test_status, :string
  end
end
