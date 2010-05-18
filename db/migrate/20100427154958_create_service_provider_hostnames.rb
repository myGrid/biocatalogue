class CreateServiceProviderHostnames < ActiveRecord::Migration
  def self.up
    create_table :service_provider_hostnames do |t|
      t.integer :service_provider_id
      t.string :hostname

      t.timestamps
    end
  end

  def self.down
    drop_table :service_provider_hostnames
  end
end
