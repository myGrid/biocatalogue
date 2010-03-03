class AddSubmitterToTestScript < ActiveRecord::Migration
  def self.up
    add_column :test_scripts, :submitter_type, :string, :default => "User"
    rename_column :test_scripts, :user_id, :submitter_id
  end

  def self.down
    remove_column :test_scripts, :submitter_type
    rename_column :test_script, :submitter_id, :user_id
  end
end
