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
    resp = ServiceResponsible.create(:user_id =>user_id, :service_id => service_id, :status => 'active')
    return ServiceResponsible.exists?(resp.id)
  end
  
end
