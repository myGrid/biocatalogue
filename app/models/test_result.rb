class TestResult < ActiveRecord::Base
  
  belongs_to :monitorable, :polymorphic => true
  
  # Helper class method to look up the object whose attribute
  # is being monitored given the monitorable class name and id 
  def self.find_monitorable(monitorable_str, monitorable_id)
    monitorable_str.constantize.find(monitorable_id)
  end
end
