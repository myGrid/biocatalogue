class UrlMonitor < ActiveRecord::Base
  
  #belongs_to :service
  belongs_to :parent , :polymorphic => true
  
  has_many :test_results, :as => :test, :dependent => :destroy
  
  
  # Helper class method to look up a pingable object
  # given the pingable class name and id 
  def self.find_parent(parent_str, parent_id)
    parent_str.constantize.find(parent_id)
  end
  
end
