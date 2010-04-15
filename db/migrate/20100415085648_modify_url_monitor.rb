class ModifyUrlMonitor < ActiveRecord::Migration
  def self.up
    add_column :url_monitors, :activated_at, :datetime, :default => Time.now
    
    execute "UPDATE url_monitors SET `activated_at`=`created_at`"
  end

  def self.down
    remove_column :url_monitors, :activated_at
  end
end
