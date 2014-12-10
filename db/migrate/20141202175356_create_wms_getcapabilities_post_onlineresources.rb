class CreateWmsGetcapabilitiesPostOnlineresources < ActiveRecord::Migration
  def change
    create_table :wms_getcapabilities_post_onlineresources do |t|
      t.string :xlink_href
      t.string :xmlns_xlink
      t.string :xlink_type
      t.references :wms_service

      t.timestamps
    end
    add_index :wms_getcapabilities_post_onlineresources, :wms_service_id
  end
end
