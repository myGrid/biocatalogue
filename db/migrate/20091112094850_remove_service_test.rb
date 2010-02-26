class RemoveServiceTest < ActiveRecord::Migration
  def self.up
    drop_table :service_tests
  end

  def self.down
    create_table :service_tests do |t|
      t.string :name
      t.string :exec_name
      t.string :test_status
      t.integer :running_status
      t.integer :testable_id, :null => false
      t.string :testable_type, :null => false
      t.text :description
      t.string :filename 
      t.string :content_type
      t.integer :user_id
      t.integer :content_blob_id, :null => false
      t.string :binding
    end
  end
end
