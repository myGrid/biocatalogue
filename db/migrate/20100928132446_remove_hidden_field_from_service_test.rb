class RemoveHiddenFieldFromServiceTest < ActiveRecord::Migration
  def self.up
    remove_column :service_tests, :hidden_at
  end

  def self.down
    add_column :service_tests, :hidden_at, :datetime
  end
end
