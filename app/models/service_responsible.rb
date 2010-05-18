class ServiceResponsible < ActiveRecord::Base
  
  belongs_to :user
  belongs_to :service
  
  validates_presence_of :user_id
  validates_presence_of :service_id
  validates_presence_of :status
  validates_existence_of :user
  validates_existence_of :service
  
  acts_as_trashable
  
  if USE_EVENT_LOG
    acts_as_activity_logged(:models => { :culprit => { :model => :user } })
  end
  
  def self.add(user_id, service_id)
    resp = ServiceResponsible.create(:user_id =>user_id, :service_id => service_id, :status => 'active')
    return ServiceResponsible.exists?(resp.id)
  end
  
end
