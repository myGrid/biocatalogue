class AddFieldFieldsToRelationships < ActiveRecord::Migration
  def self.up
    add_column :relationships, :subject_field_name, :string
    add_column :relationships, :object_field_name, :string
  end

  def self.down
    remove_column :relationships, :subject_field_name
    remove_column :relationships, :object_field_name
  end
end
