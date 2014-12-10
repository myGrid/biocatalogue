class CreateWmsOnlineResources < ActiveRecord::Migration
  def change
    create_table :wms_online_resources do |t|
      t.string :xmlns_link
      t.string :xlink_type
      t.string :xlink_href
      t.references :wms_service_node

      t.timestamps
    end
    add_index :wms_online_resources, :wms_service_node_id
  end
end
