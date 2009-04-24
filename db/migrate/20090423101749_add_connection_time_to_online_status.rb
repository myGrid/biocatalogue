class AddConnectionTimeToOnlineStatus < ActiveRecord::Migration
  def self.up
    add_column :online_statuses, :connection_time, :float, :default => 0.0
  end

  def self.down
    remove_column :online_statuses, :connection_time
  end
end
