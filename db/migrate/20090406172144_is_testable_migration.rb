class IsTestableMigration < ActiveRecord::Migration
  def self.up
    create_table :service_tests do |t|
      t.string  :name ,         :null => false
      t.string  :exec_name ,    :null => false
      t.string  :test_status,   :default =>'Unknown'
      t.integer :running_status,:default => 0
      t.integer :testable_id,   :null => false
      t.string  :testable_type, :null => false
      t.text    :description,   :null => false
      t.string  :filename,     :null => false
      t.string  :content_type, :null => false
      t.integer :user_id,      :null => false
      t.integer :content_blob_id,  :null => false
      t.datetime  :activated_at

      t.timestamps
    end
  end

  def self.down
    drop_table :service_tests
  end
end