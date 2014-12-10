class CreateWmsParameters < ActiveRecord::Migration
  def change
    create_table :wms_parameters do |t|
      t.integer :id
      t.string :name
      t.text :description
      t.string :param_style
      t.string :computational_type
      t.string :default_value
      t.boolean :required
      t.boolean :multiple
      t.boolean :constrained
      t.text :constrained_options
      t.datetime :created_at
      t.datetime :updated_at
      t.integer :submitter_id
      t.string :submitter_type
      t.boolean :is_global
      t.datetime :archived_at

      t.timestamps
    end
  end
end
