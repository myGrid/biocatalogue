class RemoveTestScriptHistory < ActiveRecord::Migration
  def self.up
    drop_table :test_script_histories
  end

  def self.down
    create_table :test_script_histories do |t|
      t.string :subject_type
      t.integer :subject_id
      t.string :predicate
      t.string :object_type
      t.integer :object_id

      t.timestamps
    end
  end
end
