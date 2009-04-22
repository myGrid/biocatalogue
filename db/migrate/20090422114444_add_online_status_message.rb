class AddOnlineStatusMessage < ActiveRecord::Migration
  def self.up
    add_column :online_statuses , :message, :string, :default =>""
  end

  def self.down
    remove_column :online_statuses, :message
  end
end
