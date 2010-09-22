class AddHiddenAtToServiceTest < ActiveRecord::Migration
  def self.up
    add_column :service_tests, :hidden_at, :datetime
  end

  def self.down
    remove_column :service_tests, :hidden_at
  end
end
