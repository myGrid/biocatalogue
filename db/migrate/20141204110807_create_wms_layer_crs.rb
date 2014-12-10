class CreateWmsLayerCrs < ActiveRecord::Migration
  def change
    create_table :wms_layer_crs do |t|
      t.string :crs
      t.references :wms_layer

      t.timestamps
    end
    add_index :wms_layer_crs, :wms_layer_id
  end
end
