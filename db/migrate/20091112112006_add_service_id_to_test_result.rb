class AddServiceIdToTestResult < ActiveRecord::Migration
  def self.up
    add_column :test_results, :service_test_id, :integer
  end

  def self.down
    remove_column :test_results, :service_test_id
  end
end
