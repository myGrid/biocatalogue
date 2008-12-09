# BioCatalogue: app/models/service.rb
#
# Copyright (c) 2008, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

class Service < ActiveRecord::Base
  acts_as_trashable
  
  acts_as_annotatable
  
  has_many :service_versions, 
           :dependent => :destroy,
           :order => "created_at ASC"
  
  has_many :service_deployments, 
           :dependent => :destroy
  
  belongs_to :submitter,
             :class_name => "User",
             :foreign_key => "submitter_id"
             
  before_validation_on_create :generate_unique_code
  
  attr_protected :unique_code
  
  validates_presence_of :name, :unique_code
  
  validates_uniqueness_of :unique_code
  
  validates_associated :service_versions
  
  validates_associated :service_deployments
  
  validates_existence_of :submitter   # User must exist in the db beforehand.
  
  if ENABLE_SEARCH
    acts_as_solr(:fields => [ :name, :unique_code, :submitter_name ],
                 :include => [ :service_versions, :service_deployments ])
  end
  
  if USE_EVENT_LOG
    acts_as_activity_logged(:models => { :culprit => { :model => :submitter } })
  end
  
  def to_param
    "#{self.id}-#{self.unique_code}"
  end
  
  def submitter_name
    if self.submitter
      return submitter.display_name
    else 
      return ''
    end
  end
  
  def latest_version
    self.service_versions.last
  end
  
  def service_version_instances
    self.service_versions.collect{|sv| sv.service_versionified}    
  end
  
  # Gets an array of all the service types that this service has (as part of it's versions).
  def service_types
    self.service_versions.collect{|sv| sv.service_versionified.service_type_name}.uniq
  end
  
  def description
    self.latest_version.service_versionified.description
  end
  
  # Gets an array of all the ServiceProviders
  def providers
    self.service_deployments.collect{|sd| sd.provider}.uniq
  end
  
protected
  
  def generate_unique_code
    salt = rand 1000000
    
    if self.name.blank?
      errors.add_to_base("Failed to generate the unique code for the Service. The name of the service has not been set yet.")
      return false
    else
      code = "#{Slugalizer.slugalize(self.name)}_#{salt}"
      
      if Service.exists?(:unique_code => code)
        generate_unique_code
      else
        self.unique_code = code
      end
    end
  end
  
end
