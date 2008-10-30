class ServiceProvider < ActiveRecord::Base
  acts_as_trashable
  
  has_many :services
  
  validates_presence_of :name
  
  if ENABLE_SEARCH
    acts_as_solr(:fields => [ :name ])
  end
end
