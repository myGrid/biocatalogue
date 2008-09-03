class CreateAnnotations < ActiveRecord::Migration
  def self.up
    create_table :annotations do |t|
      t.string :annotatable_type
      t.integer :annotatable_id
      t.string :key
      t.text :value
      t.string :source_type
      t.integer :source_id

      t.timestamps
    end
  end

  def self.down
    drop_table :annotations
  end
end
