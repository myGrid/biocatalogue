class AddBindingToServiceTest < ActiveRecord::Migration
  def self.up
    add_column :service_tests, :binding, :string
  end

  def self.down
    remove_column :service_test, :binding
  end
end
