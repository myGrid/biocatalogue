class CreateWmsKeywordlists < ActiveRecord::Migration
  def change
    create_table :wms_keywordlists do |t|
      t.integer :id
      t.string :keyword
      t.references :wms_service_node

      t.timestamps
    end
    add_index :wms_keywordlists, :wms_service_node_id
  end
end
