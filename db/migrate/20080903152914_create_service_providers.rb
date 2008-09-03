class CreateServiceProviders < ActiveRecord::Migration
  def self.up
    create_table :service_providers do |t|
      t.string :name

      t.timestamps
    end
  end

  def self.down
    drop_table :service_providers
  end
end
