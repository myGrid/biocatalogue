class CreateServiceDeployments < ActiveRecord::Migration
  def self.up
    create_table :service_deployments do |t|
      t.belongs_to :service
      t.belongs_to :service_version
      t.string :service_url
      t.belongs_to :service_provider
      t.string :city
      t.string :country
      
      t.timestamps
    end
  end

  def self.down
    drop_table :service_deployments
  end
end
