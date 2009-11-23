class CreateAnnotationProperties < ActiveRecord::Migration
  def self.up
    create_table :annotation_properties do |t|
      t.integer :annotation_id, :null=>false
      t.string :property_type, :null=>false
      t.integer :property_id, :null=>false
      t.decimal :value
      t.timestamps
      
    end
  end

  def self.down
    drop_table :annotation_properties
  end
end
