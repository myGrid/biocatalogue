class CreateOnlineStatuses < ActiveRecord::Migration
  def self.up
    create_table :online_statuses do |t|
      t.string :status
      t.integer :service_id

      t.timestamps
    end
  end

  def self.down
    drop_table :online_statuses
  end
end
