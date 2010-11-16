class RemoveArchivedAtForSoapAndRestService < ActiveRecord::Migration
  def self.up
    remove_column :soap_services, :archived_at
    remove_column :rest_services, :archived_at
  end

  def self.down
    add_column :soap_services, :archived_at, :datetime, :default => nil
    add_column :rest_services, :archived_at, :datetime, :default => nil
  end
end
