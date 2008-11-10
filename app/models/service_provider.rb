class ServiceProvider < ActiveRecord::Base
  acts_as_trashable
  
  has_many :service_deployments
  
  has_many :services,
           :through => :service_deployments,
           :uniq => true
  
  validates_presence_of :name
  
  if ENABLE_SEARCH
    acts_as_solr(:fields => [ :name ])
  end
  
  if USE_EVENT_LOG
    acts_as_activity_logged
  end
end
