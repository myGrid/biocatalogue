class AddIsGlobalToRestParameters < ActiveRecord::Migration
  def self.up
    add_column :rest_parameters, :is_global, :boolean, :default => true, :null => false

    execute 'UPDATE rest_parameters SET is_global = 1'
  end

  def self.down
    remove_column :rest_parameters, :is_global
  end
end
