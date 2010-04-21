class ModifyTestInstance < ActiveRecord::Migration
  def self.up
    remove_column :test_scripts, :activated_at
    remove_column :url_monitors, :activated_at
  end

  def self.down
    add_column :test_scripts, :activated_at, :datetime
    add_column :url_monitors, :activated_at, :datatime
    
    ServiceTest.transaction do
      TestScript.all.each do |script|
        script.activated_at = script.service_test.activated_at
        script.save!
      end
      
      UrlMonitor.all.each do |monitor|
        monitor.activated_at = monitor.service_test.activated_at
        monitor.save!
      end
    end
    
  end
  
end
