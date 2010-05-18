class CreateServiceResponsibles < ActiveRecord::Migration
  def self.up
    create_table :service_responsibles do |t|
      t.integer :user_id
      t.integer :service_id
      t.string :status
      t.string :message

      t.timestamps
    end
  end

  def self.down
    drop_table :service_responsibles
  end
end
