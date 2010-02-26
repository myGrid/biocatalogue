class AddSubmitterToRestMethodParameters < ActiveRecord::Migration
  def self.up
    add_column :rest_method_parameters, :submitter_id, :integer

    add_column :rest_method_parameters, :submitter_type, :string, :default => "User"
    execute 'UPDATE rest_method_parameters SET submitter_type = "User"'
  end

  def self.down
    remove_column :rest_method_parameters, submitter_id
    remove_column :rest_method_parameters, submitter_type
  end
end
