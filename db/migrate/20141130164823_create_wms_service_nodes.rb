class CreateWmsServiceNodes < ActiveRecord::Migration
  def change
    create_table :wms_service_nodes do |t|
      t.integer :id
      t.string :name
      t.string :title
      t.references :wms_service

      t.timestamps
    end
    add_index :wms_service_nodes, :wms_service_id
  end
end
