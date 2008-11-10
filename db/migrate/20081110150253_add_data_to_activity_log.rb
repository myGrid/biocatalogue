class AddDataToActivityLog < ActiveRecord::Migration
  def self.up
    add_column :activity_logs, :data, :binary, :limit => 1048576 # in bytes; = 1MB
  end

  def self.down
    remove_column :activity_logs, :data
  end
end
