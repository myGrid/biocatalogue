# BioCatalogue: app/models/service_responsibility.rb
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

class ServiceResponsible < ActiveRecord::Base
  
  belongs_to :user
  belongs_to :service
  
  validates_presence_of :user_id
  validates_presence_of :service_id
  validates_presence_of :status
  validates_existence_of :user
  validates_existence_of :service
  
  if ENABLE_TRASHING
    acts_as_trashable
  end
  
  if USE_EVENT_LOG
    acts_as_activity_logged(:models => { :culprit => { :model => :user } })
  end
  
  def self.add(user_id, service_id)
    unless ServiceResponsible.first(:conditions => ["user_id=? AND service_id=?", user_id, service_id])
      resp = ServiceResponsible.create(:user_id =>user_id, :service_id => service_id, :status => 'active')
      return ServiceResponsible.exists?(resp.id)
    end
    return false
  end
  
  def is_active?
    return true if self.status=='active'
    return false
  end
  
  def deactivate!
    unless !self.is_active?
      begin
          self.status = 'inactive'
          self.save!
          return true
        rescue Exception => ex
          logger.error("Failed to remove #{self.user.display_name} from reponsibility list for service #{self.service.name}:")
          logger.error(ex)
          return false
        end
      end
      logger.error("User #{self.user.display_name} is not currently responsible for service #{self.service.name}")
      return false
  end
  
  def activate!
    unless self.is_active?
      begin
          self.status = 'active'
          self.save!
          return true
        rescue Exception => ex
          logger.error("Failed to activate #{self.user.display_name} in reponsibility list for service #{self.service.name}:")
          logger.error(ex)
          return false
        end
      end
      logger.error("User #{self.user.display_name} is already responsible for service #{self.service.name}")
      return false
  end
  
end
