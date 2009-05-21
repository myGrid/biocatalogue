# BioCatalogue: app/models/service_deployment.rb
#
# Copyright (c) 2008, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

class ServiceDeployment < ActiveRecord::Base
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
    monitor = UrlMonitor.find(:first, 
                              :conditions => ["parent_id= ? AND parent_type= ?", self.id, self.class.to_s ],
                              :order => "created_at DESC" )
    
    if monitor.nil?
      return TestResult.new(:result => -1)
    end
    
    result = TestResult.find(:first,
                               :conditions => ["test_id= ? AND test_type= ?", monitor.id, monitor.class.to_s ],
                               :order => "created_at DESC" )
    return result || TestResult.new(:result => -1)
    
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
