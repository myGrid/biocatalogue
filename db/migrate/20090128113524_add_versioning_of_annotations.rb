class AddVersioningOfAnnotations < ActiveRecord::Migration
  def self.up
    add_column :annotations, :version, :integer, :null => false, :default => 1
    add_column :annotations, :version_creator_id, :integer, :null => true
    
    create_table :annotation_versions, :force => true do |t|
      t.integer   :annotation_id,       :null => false
      t.integer   :version,             :null => false
      t.integer   :version_creator_id,  :null => true
      t.string    :source_type,         :null => false
      t.integer   :source_id,           :null => false
      t.string    :annotatable_type,    :limit => 50, :null => false
      t.integer   :annotatable_id,      :null => false
      t.integer   :attribute_id,        :null => false
      t.text      :value,               :limit => 20000, :null => false
      t.string    :value_type,          :limit => 50, :null => false
      t.timestamps
    end
    
    add_index :annotation_versions, [ :annotation_id ]
  end

  def self.down
    remove_column :annotations, :version
    remove_column :annotations, :version_creator_id
    
    drop_table :annotation_versions
  end
end
