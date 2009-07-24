# BioCatalogue: app/models/service_deployment.rb
#
# Copyright (c) 2008, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

class ServiceDeployment < ActiveRecord::Base
  if ENABLE_CACHE_MONEY
    is_cached :repository => $cache
    index :service_id
    index :service_version_id
    index :endpoint
    index :service_provider_id
    index :country
    index [ :submitter_type, :submitter_id ]
  end
  
  acts_as_trashable
  
  acts_as_annotatable
  
  belongs_to :service
  
  belongs_to :provider, 
             :class_name => "ServiceProvider",
             :foreign_key => "service_provider_id"
  
  belongs_to :service_version
  
  has_submitter
  
  has_many :url_monitors, 
           :as => :parent,
           :dependent => :destroy
  
  validates_existence_of :provider    # Service Provider must exist in the db beforehand.
  
  validates_presence_of :endpoint
  
  before_save :check_service_id
  
  if ENABLE_SEARCH
    acts_as_solr(:fields => [ :endpoint, :city, :country, :submitter_name, :provider_name ])
  end
  
  if USE_EVENT_LOG
    acts_as_activity_logged(:models => { :culprit => { :model => :submitter },
                                         :referenced => { :model => :service } })
  end
  
  def location
    if self.city.blank? and self.country.blank?
      return nil
    elsif self.city.blank? or self.country.blank?
      return self.city unless self.city.blank?
      return self.country unless self.country.blank?
    else
      return "#{self.city}, #{self.country}"
    end
  end
  
  def latest_endpoint_status
    result = nil
    
    monitor = UrlMonitor.entry_for(self.class.name, self.id, "endpoint")
    
    unless monitor.nil?
      results = TestResult.results_for(monitor.class.name, monitor.id, 1)
      result = results.first unless results.empty?
    end
    
    return result || TestResult.new_with_unknown_status
  end
  
  def endpoint_recent_history
    results = [ ] 
    
    monitor = UrlMonitor.entry_for(self.class.name, self.id, "endpoint")
                              
    unless monitor.nil?
      results = TestResult.results_for(monitor.class.name, monitor.id)
    end
    
    return results
  end
  
  def provider_name
    self.provider.name
  end
  
protected

  def check_service_id
    if self.service && self.service_version
      unless self.service.id == self.service_version.service.id 
        errors.add_to_base("The service deployment doesn't belong to the same service as the associated service version.")
        return false
      end
    end
    return true
  end
  
end
