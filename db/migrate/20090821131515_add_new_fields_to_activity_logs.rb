class AddNewFieldsToActivityLogs < ActiveRecord::Migration
  def self.up
    change_column :activity_logs, :data, :text, :limit => 1.megabyte
    add_column :activity_logs, :format, :string
    execute 'UPDATE activity_logs SET format = "html"'
    add_column :activity_logs, :http_referer, :string
    add_column :activity_logs, :user_agent, :string
  end

  def self.down
    change_column :activity_logs, :data, :binary,  :limit => 1048576 # in bytes; = 1MB
    remove_column :activity_logs, :format
    remove_column :activity_logs, :http_referer
    remove_column :activity_logs, :user_agent
  end
end
