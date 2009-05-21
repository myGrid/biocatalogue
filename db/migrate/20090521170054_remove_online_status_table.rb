class RemoveOnlineStatusTable < ActiveRecord::Migration
  def self.up
    drop_table :online_statuses
  end

  def self.down
    create_table :online_statuses do |t|
      t.string :status
      t.integer :pingable_id
      t.string :pingable_type
      t.string :message
      t.float :connection_time, :default => 0.0

      t.timestamps
    end
  end
end
