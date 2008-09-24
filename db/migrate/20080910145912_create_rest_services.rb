class CreateRestServices < ActiveRecord::Migration
  def self.up
    create_table :rest_services do |t|
      t.string :name
      t.text :description

      t.timestamps
    end
  end

  def self.down
    drop_table :rest_services
  end
end
