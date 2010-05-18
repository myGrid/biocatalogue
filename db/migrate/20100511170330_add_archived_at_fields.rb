class AddArchivedAtFields < ActiveRecord::Migration
  def self.up
    add_column :services, :archived_at, :datetime, :default => nil
    add_column :soap_service_ports, :archived_at, :datetime, :default => nil
    add_column :soap_operations, :archived_at, :datetime, :default => nil
    add_column :soap_inputs, :archived_at, :datetime, :default => nil
    add_column :soap_outputs, :archived_at, :datetime, :default => nil
  end

  def self.down
    remove_column :services, :archived_at
    remove_column :soap_service_ports, :archived_at
    remove_column :soap_operations, :archived_at
    remove_column :soap_inputs, :archived_at
    remove_column :soap_outputs, :archived_at
  end
end
