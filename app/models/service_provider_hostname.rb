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
  
  if ENABLE_TRASHING
    acts_as_trashable
  end
    
  belongs_to :service_provider
  
  validates_presence_of :hostname
  validates_presence_of :service_provider_id
  
  validates_uniqueness_of :hostname
  
  if ENABLE_SEARCH
    searchable do
      text :hostname
    end
  end
  
  if USE_EVENT_LOG
    acts_as_activity_logged
  end
  
  def display_name
    self.hostname
  end
    
  def services
    # NOTE: this query has only been tested to work with MySQL 5.1.x    
    sql = "SELECT DISTINCT services.* FROM services 
           INNER JOIN service_deployments ON services.id = service_deployments.service_id 
           WHERE ((service_deployments.endpoint LIKE '%#{self.hostname}%') 
           AND (`service_deployments`.service_provider_id = #{self.service_provider.id}))"
    
    return Service.find_by_sql(sql)
    # return ActiveRecord::Base.connection.select_all(ActiveRecord::Base.send(:sanitize_sql, sql))
  end
  
  def merge_into(provider, *args)
    success = false

    return success unless provider.class==ServiceProvider
    
    transaction do
      #update deployments
      self.services.each do |service|
        service.service_deployments.each { |d|
          d.service_provider_id = provider.id 
          d.save!
        } 
      end
      
      # send emails if previously assigned service provider is now orphaned
      self.service_provider.services(true)
      self.service_provider.save!
      
      # update self
      self.service_provider_id = provider.id
      self.save!
      provider.save!
      
      success = true
    end
    
    return success
  end
  
  def associated_service_provider_id
    self.service_provider_id
  end

  def associated_service_provider
    @associated_service_provider ||= ServiceProvider.find_by_id(associated_service_provider_id)
  end    

end
