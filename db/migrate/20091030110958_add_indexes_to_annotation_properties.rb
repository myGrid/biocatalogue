class AddIndexesToAnnotationProperties < ActiveRecord::Migration
  # original migration was suitable only for Rails2.0, so updated to
  # work with Rails 1.2.6 as well
  
  def self.up
    add_index :annotation_properties, ["property_type","property_id" ], :name => "annotation_properties_property_index"
  end

  def self.down
    remove_index :annotation_properties, :name => "annotation_properties_property_index"
  end
end