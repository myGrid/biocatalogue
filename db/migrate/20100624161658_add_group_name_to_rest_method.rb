class AddGroupNameToRestMethod < ActiveRecord::Migration
  def self.up
    add_column :rest_methods, :group_name, :string
  end

  def self.down
    remove_column :rest_methods, :group_name
  end
end
