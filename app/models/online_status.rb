class OnlineStatus < ActiveRecord::Base
  #belongs_to :service
  belongs_to :pingable , :polymorphic => true
end
