class CreateWmsMethods < ActiveRecord::Migration
  def change
    create_table :wms_methods do |t|
      t.integer :id
      t.integer :wms_resource_id
      t.string :method_type
      t.text :description
      t.datetime :created_at
      t.datetime :updated_at
      t.integer :submitter_id
      t.string :submitter_type
      t.string :endpoint_name
      t.string :documentation_url
      t.string :group_name
      t.datetime :archived_at

      t.timestamps
    end
  end
end
