class AddRestServiceArchivedAtFields < ActiveRecord::Migration
  def self.up
    add_column :rest_services, :archived_at, :datetime, :default => nil
    add_column :rest_resources, :archived_at, :datetime, :default => nil
    add_column :rest_methods, :archived_at, :datetime, :default => nil
    add_column :rest_parameters, :archived_at, :datetime, :default => nil
    add_column :rest_representations, :archived_at, :datetime, :default => nil
  end

  def self.down
    remove_column :rest_services, :archived_at
    remove_column :rest_resources, :archived_at
    remove_column :rest_methods, :archived_at
    remove_column :rest_parameters, :archived_at
    remove_column :rest_representations, :archived_at
  end
end
