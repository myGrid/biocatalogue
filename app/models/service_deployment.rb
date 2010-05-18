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
  
  after_destroy :mail_provider_if_required

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
    acts_as_solr(:fields => [ :endpoint, :city, :country, :submitter_name, :provider_name, :provider_hostnames,
                              { :associated_service_id => :r_id } ])
  end
  
  if USE_EVENT_LOG
    acts_as_activity_logged(:models => { :culprit => { :model => :submitter },
                                         :referenced => { :model => :service } })
  end
  
  def has_location_info?
    !self.city.blank? || !self.country.blank?
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
      results = TestResult.results_for(monitor.service_test, 1)
      result = results.first unless results.empty?
    end
    
    return result || TestResult.new_with_unknown_status
  end
  
  def endpoint_recent_history
    results = [ ] 
    
    monitor = UrlMonitor.entry_for(self.class.name, self.id, "endpoint")
                              
    unless monitor.nil?
      results = TestResult.results_for(monitor.service_test)
    end
    
    return results
  end
  
  def provider_name
    self.provider.name
  end
  
  def provider_hostnames
    hostnames = ""
    self.provider.service_provider_hostnames.each { |h| hostnames << h.hostname + " " }
    return hostnames.strip
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
  
  def associated_service_id
    BioCatalogue::Mapper.map_compound_id_to_associated_model_object_id(BioCatalogue::Mapper.compound_id_for(self.class.name, self.id), "Service")
  end

private
  
  def mail_provider_if_required    
    # send emails to biocat admins
    if self.provider.services.empty?
      recipients = []
      User.admins.each { |user| recipients << user.email }

      UserMailer.deliver_orphaned_provider_notification(recipients.join(", "), SITE_BASE_HOST, provider)
    end
  end
  
end
