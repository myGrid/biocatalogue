class ModifyTestResult < ActiveRecord::Migration
  def self.up
    change_table :test_results do |t|
      t.change :message, :text
    end
  end

  def self.down
    change_table :test_results do |t|
      t.change :message, :string
    end
  end
end
