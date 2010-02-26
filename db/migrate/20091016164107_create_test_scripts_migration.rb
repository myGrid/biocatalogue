class CreateTestScriptsMigration < ActiveRecord::Migration
  def self.up
    create_table :test_scripts do |t|
      t.string  :name ,         :null => false
      t.string  :exec_name ,    :null => false
      t.string  :test_status,   :default =>'Unknown'
      t.integer :testable_id,   :null => false
      t.string  :testable_type, :null => false
      t.text    :description,   :null => false
      t.string  :filename,     :null => false
      t.string  :content_type, :null => false
      t.integer :user_id,      :null => false
      t.integer :content_blob_id,  :null => false
      t.datetime  :activated_at
      t.string :prog_language, :null => false

      t.timestamps
    end
  end

  def self.down
    drop_table :test_scripts
  end
end