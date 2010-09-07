class AddSoapServiceArchivedAtField < ActiveRecord::Migration
  def self.up
    add_column :soap_services, :archived_at, :datetime, :default => nil
  end

  def self.down
    remove_column :soap_services, :archived_at
  end
end
