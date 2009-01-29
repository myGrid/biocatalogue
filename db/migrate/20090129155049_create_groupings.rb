class CreateGroupings < ActiveRecord::Migration
  def self.up
    create_table :groupings do |t|
      t.string :subject_type
      t.integer :subject_id
      t.string :predicate
      t.string :object_type
      t.integer :object_id

      t.timestamps
    end
  end

  def self.down
    drop_table :groupings
  end
end
