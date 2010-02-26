class AddSubmitterToRestResources < ActiveRecord::Migration
  def self.up
    add_column :rest_resources, :submitter_id, :integer

    add_column :rest_resources, :submitter_type, :string, :default => "User"
    execute 'UPDATE rest_resources SET submitter_type = "User"'
  end

  def self.down
    remove_column :rest_resources, submitter_id
    remove_column :rest_resources, submitter_type
  end
end
