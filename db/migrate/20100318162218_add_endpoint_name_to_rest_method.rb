class AddEndpointNameToRestMethod < ActiveRecord::Migration
  def self.up
    add_column :rest_methods, :endpoint_name, :string
    execute 'UPDATE rest_methods SET endpoint_name = NULL'
  end

  def self.down
    remove_column :rest_methods, :endpoint_name
  end
end
