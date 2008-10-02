class CreateServiceVersions < ActiveRecord::Migration
  def self.up
    create_table :service_versions do |t|
      t.belongs_to :service
      t.references :service_versionified, :polymorphic => true
      t.string :version

      t.timestamps
    end
  end

  def self.down
    drop_table :service_versions
  end
end
