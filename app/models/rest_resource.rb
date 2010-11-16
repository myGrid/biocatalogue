# BioCatalogue: app/models/rest_resource.rb
#
# Copyright (c) 2009-2010, University of Manchester, The European Bioinformatics
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

  if ENABLE_TRASHING
    acts_as_trashable
  end
  
  acts_as_annotatable
  
  acts_as_archived
  
  validates_presence_of :rest_service_id, 
                        :path
                        
  belongs_to :rest_service
  
  belongs_to :parent_resource,
             :class_name => "RestResource",
             :foreign_key => "parent_resource_id"
  
  has_many :rest_methods, 
           :dependent => :destroy,
           :include => [ :rest_method_parameters, :rest_method_representations ],
           :conditions => "rest_methods.archived_at IS NULL",
           :order => "rest_methods.method_type ASC"
           
  has_many :archived_rest_methods,
           :class_name => "RestMethod",
           :foreign_key => "rest_resource_id",
           :dependent => :destroy,
           :include => [ :rest_method_parameters, :rest_method_representations ],
           :conditions => "rest_methods.archived_at IS NOT NULL",
           :order => "rest_methods.method_type ASC"

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
    return self.path <=> other.path
  end
  
  def display_name
    self.path
  end
  
  # This returns an Array of Hashes that has the grouped and sorted rest_methods of this .
  #
  # Example output:
  #   [ { :group_name => "..", :items => [ ... ] }, { :group_name => "..", :items => [ ... ] }  ]
  def rest_methods_grouped
    return RestMethod.group_rest_methods(self.rest_methods)
  end

  # =========================================
  
  def to_json
    generate_json_and_make_inline(false)
  end 

  def to_inline_json
    generate_json_and_make_inline(true)
  end 

  def associated_service_id
    @associated_service_id ||= BioCatalogue::Mapper.map_compound_id_to_associated_model_object_id(BioCatalogue::Mapper.compound_id_for(self.class.name, self.id), "Service")
  end
  
  def associated_service
    @associated_service ||= Service.find_by_id(associated_service_id)
  end

private

  def generate_json_and_make_inline(make_inline)
    data = {
      "rest_resource" => {
        "path" => self.path,
        "submitter" => BioCatalogue::Api.uri_for_object(self.submitter),
        "created_at" => self.created_at.iso8601
      }
    }
    
    unless make_inline
      data["rest_resource"]["methods"] = BioCatalogue::Api::Json.collection(self.rest_methods)
      data["rest_resource"]["self"] = BioCatalogue::Api.uri_for_object(self)
			return data.to_json
    else
      data["rest_resource"]["resource"] = BioCatalogue::Api.uri_for_object(self)
			return data["rest_resource"].to_json
    end
  end # generate_json_and_make_inline

end
