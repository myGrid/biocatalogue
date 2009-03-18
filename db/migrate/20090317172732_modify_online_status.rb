class ModifyOnlineStatus < ActiveRecord::Migration
  def self.up
    rename_column :online_statuses , :service_id , :pingable_id
    add_column :online_statuses , :pingable_type, :string
  end

  def self.down
    rename_column :online_statuses , :pingable_id , :service_id 
    remove_column :online_statuses , :pingable_type
  end
end
