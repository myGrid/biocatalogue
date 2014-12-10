class CreateWmsResources < ActiveRecord::Migration
  def change
    create_table :wms_resources do |t|
      t.integer :id
      t.integer :wms_service_id
      t.string :path
      t.text :description
      t.integer :parent_resource_id
      t.datetime :created_at
      t.datetime :updated_at
      t.integer :submitter_id
      t.string :submitter_type
      t.datetime :archived_at

      t.timestamps
    end
  end
end
