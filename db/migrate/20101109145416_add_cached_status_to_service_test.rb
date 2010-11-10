class AddCachedStatusToServiceTest < ActiveRecord::Migration
  def self.up
    add_column :service_tests, :cached_status, :integer
  end

  def self.down
    remove_column :service_tests, :cached_status
  end
end
