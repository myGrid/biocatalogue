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
  
  belongs_to :submitter,
             :class_name => "User",
             :foreign_key => "submitter_id"
  
  has_many :online_statuses , :as => :pingable
  
  validates_existence_of :provider    # Service Provider must exist in the db beforehand.
  
  validates_presence_of :endpoint
  
  before_save :check_service_id
  
  if ENABLE_SEARCH
    acts_as_solr(:fields => [ :endpoint, :city, :country ],
                 :include => [ :provider ] )
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
  
  def latest_online_status
    status = OnlineStatus.find(:first, :conditions => ["pingable_id= ? AND pingable_type= ?", self.id, self.class.to_s ],
                                    :order => "created_at DESC")
    if status == nil
      status = OnlineStatus.create(:status => "Unknown", :pingable_id => self.id, :pingable_type => self.class.to_s)
    end
    status
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
