class CreateRegistries < ActiveRecord::Migration
  def self.up
    create_table :registries do |t|
      t.string :name
      t.string :display_name
      t.text :description
      t.string :homepage
      
      t.timestamps
    end
  end

  def self.down
    drop_table :registries
  end
end
