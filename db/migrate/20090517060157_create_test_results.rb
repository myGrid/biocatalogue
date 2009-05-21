class CreateTestResults < ActiveRecord::Migration
  def self.up
    create_table :test_results do |t|
      t.integer :test_id
      t.string :test_type
      t.integer :result
      t.string :action
      t.string :message

      t.timestamps
    end
  end

  def self.down
    drop_table :test_results
  end
end
