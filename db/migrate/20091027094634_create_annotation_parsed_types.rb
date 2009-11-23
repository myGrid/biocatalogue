class CreateAnnotationParsedTypes < ActiveRecord::Migration
  def self.up
    create_table :annotation_parsed_types do |t|
      t.integer :annotation_id, :null=>false
      t.string  :parsed_type
      t.timestamps
    end
  end

  def self.down
    drop_table :annotation_parsed_types
  end
end
