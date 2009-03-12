# BioCatalogue: app/models/rest_method.rb
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

class RestMethod < ActiveRecord::Base
  acts_as_trashable
  
  acts_as_annotatable
  
  validates_presence_of :rest_resource_id, 
                        :method_type
  
  belongs_to :rest_resource
  
  # =====================
  # Associated Parameters
  # ---------------------
  
  # Avoid using this association directly. 
  # Use the specific ones defined below.
  has_many :rest_method_parameters,
           :dependent => :destroy
  
  has_many :request_parameters,
           :through => :rest_method_parameters,
           :source => :rest_parameter,
           :class_name => "RestParameter",
           :conditions => [ "rest_method_parameters.http_cycle = ?", "request" ]
  
  has_many :response_parameters,
           :through => :rest_method_parameters,
           :source => :rest_parameter,
           :class_name => "RestParameter",
           :conditions => [ "rest_method_parameters.http_cycle = ?", "response" ]
           
  # =====================
  
  
  # ==========================
  # Associated Representations
  # --------------------------
  
  # Avoid using this association directly. 
  # Use the specific ones defined below.
  has_many :rest_method_representations,
           :dependent => :destroy
  
  has_many :request_representations,
           :through => :rest_method_representations,
           :source => :rest_representation,
           :class_name => "RestRepresentation",
           :conditions => [ "rest_method_representations.http_cycle = ?", "request" ]
  
  has_many :request_representations,
           :through => :rest_method_representations,
           :source => :rest_representation,
           :class_name => "RestRepresentation",
           :conditions => [ "rest_method_representations.http_cycle = ?", "response" ]
  
  # ==========================
  
  
  if ENABLE_SEARCH
    acts_as_solr(:fields => [ :method_type, :description ])
  end
  
  if USE_EVENT_LOG
    acts_as_activity_logged(:models => { :referenced => { :model => :rest_resource } })
  end
end
