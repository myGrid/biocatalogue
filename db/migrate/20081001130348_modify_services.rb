class ModifyServices < ActiveRecord::Migration
  def self.up
    remove_column :services, :service_type
    add_column :services, :name, :string
  end

  def self.down
    add_column :services, :service_type, :string
    remove_column :services, :name
  end
end
