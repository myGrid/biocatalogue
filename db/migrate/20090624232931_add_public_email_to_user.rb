class AddPublicEmailToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :public_email, :string
    add_column :users, :receive_notifications, :boolean, :default => false
  end

  def self.down
    remove_column :users, :public_email
    remove_column :users, :receive_notifications
  end
end
