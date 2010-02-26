class CreateServiceTests < ActiveRecord::Migration
  def self.up
    create_table :service_tests do |t|
      t.integer :test_id
      t.string :test_type
      t.integer :service_id

      t.timestamps
    end
  end

  def self.down
    drop_table :service_tests
  end
end
