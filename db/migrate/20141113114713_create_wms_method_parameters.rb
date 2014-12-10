class CreateWmsMethodParameters < ActiveRecord::Migration
  def change
    create_table :wms_method_parameters do |t|
      t.integer :id
      t.integer :wms_method_id
      t.integer :wms_parameter_id
      t.string :http_cycle
      t.datetime :created_at
      t.datetime :updated_at
      t.integer :submitter_id
      t.string :submitter_type

      t.timestamps
    end
  end
end
