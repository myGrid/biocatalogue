class ActsAsAnnotatable < ActiveRecord::Migration
  def self.up
    create_table :annotations, :force => true do |t|
      t.string   :annotatable_type, :limit => 50, :null => false
      t.integer  :annotatable_id, :null => false
      t.string   :key,            :null => false
      t.text     :value,          :null => false
      t.string   :source_type,    :null => false
      t.integer  :source_id,      :null => false
      
      t.timestamps
    end
    
    add_index :annotations, [:annotatable_type, :annotatable_id]
    add_index :annotations, [:key, :value]
    add_index :annotations, [:source_type, :source_id]
  end
  
  def self.down
    drop_table :annotations
  end
end