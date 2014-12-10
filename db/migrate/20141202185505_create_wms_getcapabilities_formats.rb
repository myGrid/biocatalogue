class CreateWmsGetcapabilitiesFormats < ActiveRecord::Migration
  def change
    create_table :wms_getcapabilities_formats do |t|
      t.string :format
      t.references :wms_service_id

      t.timestamps
    end
    add_index :wms_getcapabilities_formats, :wms_service_id_id
  end
end
