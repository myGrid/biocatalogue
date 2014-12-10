class WmsRepresentation < ActiveRecord::Base
  attr_accessible :content_type, :created_at, :description, :http_status, :id, :submitter_id, :submitter_type, :updated_at, :archived_at

  if ENABLE_CACHE_MONEY
    is_cached :repository => $cache
    index [ :submitter_type, :submitter_id ]
  end

  if ENABLE_TRASHING
    acts_as_trashable
  end

  acts_as_annotatable :name_field => :content_type

  acts_as_archived

  validates_presence_of :content_type

  has_submitter

  validates_existence_of :submitter # User must exist in the db beforehand.

  if ENABLE_SEARCH
    searchable do
      text :content_type, :description, :submitter_name
    end
  end

  if USE_EVENT_LOG
    acts_as_activity_logged(:models => { :culprit => { :model => :submitter } })
  end


  def display_name
    return self.content_type
  end

  # ========================================

  # get all the WmsMethodRepresentations that use this WmsRepresentation
  def wms_method_representations
    WmsMethodRepresentation.find_all_by_wms_representation_id(self.id)
  end


  # For the given wms_method object, find duplicate entry based on 'representation' and http_cycle
  # When http_cycle == "request", search the method's request representations for a dup.
  # When http_cycle == "response", search the method's response representations for a dup.
  # Otherwise search both request and response representations for a dup.
  def self.check_duplicate(wms_method, representation, http_cycle="")
    case http_cycle
      when "request"
        rep = wms_method.request_representations.find_by_content_type(representation)
      when "response"
        rep = wms_method.response_representations.find_by_content_type(representation)
      else
        rep = wms_method.request_representations.find_by_content_type(representation)
        rep = wms_method.response_representations.find_by_content_type(representation) unless rep
    end

    return rep # WmsRepresentation || nil
  end

  # Check that a given representation exists for the given wms_service object
  def self.check_exists_for_wms_service(wms_service, representation)
    rep = nil

    wms_service.wms_resources.each do |resource|
      resource.wms_methods.each { |method|
        rep = WmsRepresentation.check_duplicate(method, representation)
        break if rep
      }
      break if rep
    end

    return rep # WmsRepresentation || nil
  end

  def associated_service_id
    @associated_service_id ||= BioCatalogue::Mapper.map_compound_id_to_associated_model_object_id(BioCatalogue::Mapper.compound_id_for(self.class.name, self.id), "Service")
  end

  def associated_service
    @associated_service ||= Service.find_by_id(associated_service_id)
  end

  def associated_wms_method_id
    @associated_wms_method_id ||= BioCatalogue::Mapper.map_compound_id_to_associated_model_object_id(BioCatalogue::Mapper.compound_id_for(self.class.name, self.id), "WmsMethod")
  end

  def associated_wms_method
    @associated_wms_method ||= WmsMethod.find_by_id(associated_wms_method_id)
  end

  def to_json
    generate_json_and_make_inline(false)
  end

  def to_inline_json
    generate_json_and_make_inline(true)
  end

  def preferred_description
    # Either the description from the service description doc,
    # or the last description annotation.

    desc = self.description

    if desc.blank?
      desc = self.annotations_with_attribute("description", true).first.try(:value_content)
    end

    return desc
  end

  private

  def generate_json_and_make_inline(make_inline)
    data = {
        "wms_representation" => {
            "content_type" => self.content_type,
            "description" => self.preferred_description,
            "submitter" => BioCatalogue::Api.uri_for_object(self.submitter),
            "created_at" => self.created_at.iso8601,
            "archived_at" => self.archived? ? self.archived_at.iso8601 : nil
        }
    }

    unless make_inline
      data["wms_representation"]["self"] = BioCatalogue::Api.uri_for_object(self)
      return data.to_json
    else
      data["wms_representation"]["resource"] = BioCatalogue::Api.uri_for_object(self)
      return data["wms_representation"].to_json
    end
  end # generate_json_and_make_inline
end
