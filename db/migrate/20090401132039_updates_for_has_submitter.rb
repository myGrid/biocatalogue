class UpdatesForHasSubmitter < ActiveRecord::Migration
  def self.up
    add_column :services, :submitter_type, :string
    execute 'UPDATE services SET submitter_type = "User"'
    
    add_column :service_versions, :submitter_type, :string
    execute 'UPDATE service_versions SET submitter_type = "User"'
    
    add_column :service_deployments, :submitter_type, :string
    execute 'UPDATE service_deployments SET submitter_type = "User"'
  end

  def self.down
    remove_column :services, :submitter_type
    remove_column :service_versions, :submitter_type
    remove_column :service_deployments, :submitter_type
  end
end
