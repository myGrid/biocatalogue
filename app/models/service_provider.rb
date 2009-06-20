# BioCatalogue: app/models/service_provider.rb
#
# Copyright (c) 2008, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

class ServiceProvider < ActiveRecord::Base
  if ENABLE_CACHE_MONEY
    is_cached :repository => $cache
    index :name
  end
  
  acts_as_trashable
  
  acts_as_annotation_source
  
  has_many :service_deployments
  
  has_many :services,
           :through => :service_deployments,
           :uniq => true
  
  validates_presence_of :name
  
  if ENABLE_SEARCH
    acts_as_solr(:fields => [ :name ] )
  end
  
  if USE_EVENT_LOG
    acts_as_activity_logged
  end
end
