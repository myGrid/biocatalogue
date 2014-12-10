class CreateWmsContactInformations < ActiveRecord::Migration
  def change
    create_table :wms_contact_informations do |t|
      t.string :contact_person_primary
      t.string :contact_organization
      t.string :contact_position_
      t.string :address_type
      t.string :address
      t.string :city
      t.string :state_or_province
      t.string :post_code
      t.string :country
      t.references :wms_service_node

      t.timestamps
    end
    add_index :wms_contact_informations, :wms_service_node_id
  end
end
