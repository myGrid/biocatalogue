class CreateResponsibilityRequests < ActiveRecord::Migration
  def self.up
    create_table :responsibility_requests do |t|
      t.integer :user_id
      t.integer :subject_id
      t.string :subject_type
      t.string :status, :defualt => 'pending'
      t.string :message

      t.timestamps
    end
  end

  def self.down
    drop_table :responsibility_requests
  end
end
