class AddSubmitterToRestMethods < ActiveRecord::Migration
  def self.up
    add_column :rest_methods, :submitter_id, :integer

    add_column :rest_methods, :submitter_type, :string, :default => "User"
    execute 'UPDATE rest_methods SET submitter_type = "User"'
  end

  def self.down
    remove_column :rest_methods, submitter_id
    remove_column :rest_methods, submitter_type
  end
end
