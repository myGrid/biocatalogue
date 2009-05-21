class CreateUrlMonitors < ActiveRecord::Migration
  def self.up
    create_table :url_monitors do |t|
      t.integer :parent_id
      t.string :parent_type
      t.string :property

      t.timestamps
    end
  end

  def self.down
    drop_table :url_monitors
  end
end
