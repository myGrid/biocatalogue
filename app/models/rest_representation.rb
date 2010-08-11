# BioCatalogue: app/models/rest_representation.rb
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

class RestRepresentation < ActiveRecord::Base
  if ENABLE_CACHE_MONEY
    is_cached :repository => $cache
    index [ :submitter_type, :submitter_id ]
  end
  
  if ENABLE_TRASHING
    acts_as_trashable
  end
  
  acts_as_annotatable

  validates_presence_of :content_type
  
  has_submitter
  
  validates_existence_of :submitter # User must exist in the db beforehand.

  if ENABLE_SEARCH
    acts_as_solr(:fields => [ :content_type, :description, :submitter_name,
                              { :associated_service_id => :r_id },
                              { :associated_rest_method_id => :r_id } ] )
  end

  if USE_EVENT_LOG
    acts_as_activity_logged(:models => { :culprit => { :model => :submitter } })
  end


  def display_name 
    return self.content_type
  end

  # ========================================
  
  # get all the RestMethodRepresentations that use this RestRepresentation
  def rest_method_representations
    RestMethodRepresentation.find_all_by_rest_representation_id(self.id)
  end


  # For the given rest_method object, find duplicate entry based on 'representation' and http_cycle
  # When http_cycle == "request", search the method's request representations for a dup.
  # When http_cycle == "response", search the method's response representations for a dup.
  # Otherwise search both request and response representations for a dup.
  def self.check_duplicate(rest_method, representation, http_cycle="")
    case http_cycle
      when "request"
        rep = rest_method.request_representations.find_by_content_type(representation)
      when "response"
        rep = rest_method.response_representations.find_by_content_type(representation)
      else
        rep = rest_method.request_representations.find_by_content_type(representation)
        rep = rest_method.response_representations.find_by_content_type(representation) unless rep
    end
    
    return rep # RestRepresentation || nil
  end

  # Check that a given representation exists for the given rest_service object
  def self.check_exists_for_rest_service(rest_service, representation)
    rep = nil
    
    rest_service.rest_resources.each do |resource|
      resource.rest_methods.each { |method| 
        rep = RestRepresentation.check_duplicate(method, representation)
        break if rep
      }
      break if rep
    end
    
    return rep # RestRepresentation || nil
  end

  def associated_service_id
    BioCatalogue::Mapper.map_compound_id_to_associated_model_object_id(BioCatalogue::Mapper.compound_id_for(self.class.name, self.id), "Service")
  end
  
  def associated_rest_method_id
    return RestMethodRepresentation.find_by_rest_representation_id(self.id).try(:rest_method_id)
  end

  def to_json
    {
      "rest_representation" => {
        "self" => BioCatalogue::Api.uri_for_object(self),
        "content_type" => self.content_type,
        "description" => self.description,
        "submitter" => BioCatalogue::Api.uri_for_object(self.submitter),
        "created_at" => self.created_at.iso8601
      }
    }.to_json
  end

end
