# BioCatalogue: app/models/rest_resource.rb
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

class RestResource < ActiveRecord::Base
  if ENABLE_CACHE_MONEY
    is_cached :repository => $cache
    index :rest_service_id
    index :parent_resource_id
    index [ :submitter_type, :submitter_id ]
  end
  
  has_submitter
  
  validates_existence_of :submitter # User must exist in the db beforehand.

  acts_as_trashable
  
  acts_as_annotatable
  
  validates_presence_of :rest_service_id, 
                        :path
                        
  belongs_to :rest_service
  
  belongs_to :parent_resource,
             :class_name => "RestResource",
             :foreign_key => "parent_resource_id"
  
  has_many :rest_methods, 
           :dependent => :destroy,
           :include => [ :rest_method_parameters, :rest_method_representations ]
           
  if ENABLE_SEARCH
    acts_as_solr(:fields => [ :path, :description, :submitter_name, { :associated_service_id => :r_id } ])
  end
  
  if USE_EVENT_LOG
    acts_as_activity_logged(:models => {:referenced => { :model => :rest_service },
                                        :culprit => { :model => :submitter }})
  end
  
  # For the given rest_service object, find duplicate entry based on 'resource_path'
  def self.check_duplicate(rest_service, resource_path)
    return rest_service.rest_resources(true).find_by_path(resource_path) # RestResource || nil
  end
  
  # for sort
  def <=>(other)
    comparison = self.path <=> other.path
    return comparison unless comparison==0
  end

  # =========================================
  
  
  protected
  
  def associated_service_id
    BioCatalogue::Mapper.map_compound_id_to_associated_model_object_id(BioCatalogue::Mapper.compound_id_for(self.class.name, self.id), "Service")
  end

end
