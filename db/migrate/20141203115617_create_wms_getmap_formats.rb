class CreateWmsGetmapFormats < ActiveRecord::Migration
  def change
    create_table :wms_getmap_formats do |t|
      t.string :format
      t.references :wms_service

      t.timestamps
    end
    add_index :wms_getmap_formats, :wms_service_id
  end
end
