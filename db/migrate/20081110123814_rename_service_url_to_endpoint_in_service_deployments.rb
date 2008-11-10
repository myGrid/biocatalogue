class RenameServiceUrlToEndpointInServiceDeployments < ActiveRecord::Migration
  def self.up
    rename_column :service_deployments, :service_url, :endpoint
  end

  def self.down
    rename_column :service_deployments, :endpoint, :service_url
  end
end
