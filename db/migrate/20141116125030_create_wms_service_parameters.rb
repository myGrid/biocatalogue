class CreateWmsServiceParameters < ActiveRecord::Migration
  def change
    create_table :wms_service_parameters do |t|
      t.integer :id
      t.text :xml_content

      t.timestamps
    end
  end
end
