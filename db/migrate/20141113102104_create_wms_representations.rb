class CreateWmsRepresentations < ActiveRecord::Migration
  def change
    create_table :wms_representations do |t|
      t.integer :id
      t.string :content_type
      t.text :description
      t.string :http_status
      t.datetime :created_at
      t.datetime :updated_at
      t.integer :submitter_id
      t.string :submitter_type
      t.datetime :archived_at

      t.timestamps
    end
  end
end
