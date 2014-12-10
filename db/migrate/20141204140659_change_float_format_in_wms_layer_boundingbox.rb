class ChangeFloatFormatInWmsLayerBoundingbox < ActiveRecord::Migration
  def up
    change_column :wms_layer_boundingboxes, :minx, :string
    change_column :wms_layer_boundingboxes, :miny, :string
    change_column :wms_layer_boundingboxes, :maxx, :string
    change_column :wms_layer_boundingboxes, :maxy, :string
  end

  def down
    change_column :wms_layer_boundingboxes, :minx, :string
    change_column :wms_layer_boundingboxes, :miny, :string
    change_column :wms_layer_boundingboxes, :maxx, :string
    change_column :wms_layer_boundingboxes, :maxy, :string

  end
end
