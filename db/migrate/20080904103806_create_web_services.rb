class CreateWebServices < ActiveRecord::Migration
  def self.up
    create_table :web_services do |t|
      t.string :service_type
      t.string :unique_code

      t.timestamps
    end
  end

  def self.down
    drop_table :web_services
  end
end
