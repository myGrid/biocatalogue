class RemoveServiceTypes < ActiveRecord::Migration
  def self.up
    drop_table :service_types
  end

  def self.down
    create_table :service_types do |t|
      t.string :name

      t.timestamps
    end
  end
end
