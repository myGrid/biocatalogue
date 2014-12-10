class CreateWmsServices < ActiveRecord::Migration
  def change
    create_table :wms_services do |t|
      t.integer :id
      t.string :name
      t.text :description
      t.datetime :created_at
      t.datetime :updated_at
      t.string :interface_doc_url
      t.string :documentation_url

      t.timestamps
    end
  end
end
