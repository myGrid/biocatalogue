class CreateWmsLayerBoundingboxes < ActiveRecord::Migration
  def change
    create_table :wms_layer_boundingboxes do |t|
      t.string :crs
      t.float :minx
      t.float :miny
      t.float :maxx
      t.float :maxy
      t.references :wms_layer

      t.timestamps
    end
    add_index :wms_layer_boundingboxes, :wms_layer_id
  end
end
