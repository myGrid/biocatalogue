class AddSuccessRateToServiceTest < ActiveRecord::Migration
  def self.up
    add_column :service_tests, :success_rate, :integer
  end

  def self.down
    remove_column :service_tests, :success_rate
  end
end
