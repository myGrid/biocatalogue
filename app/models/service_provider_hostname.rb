# BioCatalogue: app/models/service_provider_hostname.rb
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

class ServiceProviderHostname < ActiveRecord::Base
  if ENABLE_CACHE_MONEY
    is_cached :repository => $cache
    index :hostname
  end
  
  acts_as_trashable
    
  belongs_to :service_provider
  
  validates_presence_of :hostname
  validates_presence_of :service_provider_id
  
  validates_uniqueness_of :hostname
  
  if ENABLE_SEARCH
    acts_as_solr(:fields => [ :hostname, { :associated_service_provider_id => :r_id } ] )
  end
  
  if USE_EVENT_LOG
    acts_as_activity_logged
  end
  
  protected
  
  def associated_service_provider_id
    self.service_provider_id
  end

end
