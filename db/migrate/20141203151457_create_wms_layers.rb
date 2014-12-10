class CreateWmsLayers < ActiveRecord::Migration
  def change
    create_table :wms_layers do |t|
      t.string :name
      t.string :title
      t.text :abstract
      t.float :west_bound_longitude
      t.float :east_bound_longitude
      t.float :south_bound_latitude
      t.float :north_bound_latitude
      t.references :wms_service

      t.timestamps
    end
    add_index :wms_layers, :wms_service_id
  end
end
