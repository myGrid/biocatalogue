class AddSubmitterIdToServiceVersionsAndServiceDeployments < ActiveRecord::Migration
  def self.up
    add_column :service_versions, :submitter_id, :integer
    add_column :service_deployments, :submitter_id, :integer
  end

  def self.down
    remove_column :service_versions, :submitter_id
    remove_column :service_deployments, :submitter_id
  end
end
