class OnlineStatus < ActiveRecord::Base
  #belongs_to :service
  belongs_to :pingable , :polymorphic => true
  
  #has_many :test_results, :as => :monitorable, :dependent => :destroy
  
  
  # Helper class method to look up a pingable object
  # given the pingable class name and id 
  def self.find_pingable(pingable_str, pingable_id)
    pingable_str.constantize.find(pingable_id)
  end
  
end
