class AddActionAndActivityLoggableIndexToActivityLogs < ActiveRecord::Migration
  def self.up
    change_column :activity_logs, :action, :string, :limit => 60
    change_column :activity_logs, :activity_loggable_type, :string, :limit => 60
    change_column :activity_logs, :culprit_type, :string, :limit => 60
    change_column :activity_logs, :referenced_type, :string, :limit => 60
    
    add_index :activity_logs, [ :action, :activity_loggable_type ], :name => "act_logs_forfeeds_index"
  end

  def self.down
    remove_index :activity_logs, :name => "act_logs_forfeeds_index"
    
    change_column :activity_logs, :action, :string, :limit => 255
    change_column :activity_logs, :activity_loggable_type, :string, :limit => 255
    change_column :activity_logs, :culprit_type, :string, :limit => 255
    change_column :activity_logs, :referenced_type, :string, :limit => 255
  end
end
