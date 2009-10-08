class AddIndexesToActivityLogs < ActiveRecord::Migration
  def self.up
    add_index :activity_logs, [ "action" ], :name => "act_logs_action_index"
    add_index :activity_logs, [ "activity_loggable_type", "activity_loggable_id" ], :name => "act_logs_act_loggable_index"
    add_index :activity_logs, [ "culprit_type", "culprit_id" ], :name => "act_logs_culprit_index"
    add_index :activity_logs, [ "referenced_type", "referenced_id" ], :name => "act_logs_referenced_index"
    add_index :activity_logs, [ "format" ], :name => "act_logs_format_index"
  end

  def self.down
    remove_index :activity_logs, :name => "act_logs_action_index"
    remove_index :activity_logs, :name => "act_logs_act_loggable_index"
    remove_index :activity_logs, :name => "act_logs_culprit_index"
    remove_index :activity_logs, :name => "act_logs_referenced_index"
    remove_index :activity_logs, :name => "act_logs_format_index"
  end
end
