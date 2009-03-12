# BioCatalogue: app/models/rest_service.rb
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

require 'acts_as_service_versionified'

class RestService < ActiveRecord::Base
  acts_as_trashable
  
  acts_as_service_versionified
  
  acts_as_annotatable
  
  has_many :rest_resources,
           :dependent => :destroy,
           :include => [ :rest_methods, :parent_resource ]
  
  validates_presence_of :name
  
  validates_associated :rest_resources
  
  validates_url_format_of :interface_doc_url,
                          :allow_nil => true,
                          :message => 'is not valid'
                          
  validates_url_format_of :documentation_url,
                          :allow_nil => true,
                          :message => 'is not valid'

  if ENABLE_SEARCH
    acts_as_solr(:fields => [ :name, :description, :interface_doc_url, :documentation_url, :service_type_name ])
  end
  
  if USE_EVENT_LOG
    acts_as_activity_logged(:models => { :referenced => { :model => :service_version } })
  end
  
  
  # ======================================
  # Class level method stubs reimplemented
  # from acts_as_service_versionified
  # --------------------------------------
  
  def self.check_duplicate(endpoint)
    obj = ServiceDeployment.find(:first, :conditions => { :endpoint => endpoint })
          
    return (obj.nil? ? nil : obj.service)
  end
  
  # ======================================
  
  
  # =========================================
  # Instance level method stubs reimplemented
  # from acts_as_service_versionified
  # -----------------------------------------
  
  def service_type_name
    "REST"
  end
  
  # This method returns a count of all the annotations for this REST Service.
  # This takes into account annotations on all the child resources/methods/parameters/representations.
  def total_annotations_count(source_type)
    count = 0
    
    count += self.count_annotations_by(source_type)
    
    # TODO: get counts for resources, methods, parameters and representations.
    
    return count
  end
  
  # =========================================
  
  
  def submit_service(endpoint, current_user, annotations)
    transaction do
      self.save!
      self.perform_post_submit(endpoint, current_user)
      self.create_annotations(annotations, current_user)
      return true
    end
    rescue Exception => ex
      #ActiveRecord::RecordNotSaved, ActiveRecord::RecordInvalid
      logger.error("ERROR: failed to submit REST service - #{endpoint}. Exception:")
      logger.error(ex)
      return false
  end
end
