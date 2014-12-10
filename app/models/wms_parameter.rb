class WmsParameter < ActiveRecord::Base
  attr_accessible :archived_at, :computational_type, :constrained, :constrained_options, :created_at, :default_value, :description, :id, :is_global, :multiple, :name, :param_style, :required, :submitter_id, :submitter_type, :updated_at

  if ENABLE_CACHE_MONEY
    is_cached :repository => $cache
    index [ :submitter_type, :submitter_id ]
  end

  if ENABLE_TRASHING
    acts_as_trashable
  end

  acts_as_annotatable :name_field => :name

  acts_as_archived

  validates_presence_of :name,
                        :param_style

  has_submitter

  validates_existence_of :submitter # User must exist in the db beforehand.

  if ENABLE_SEARCH
    searchable do
      text :name, :submitter_name, :description
    end
  end

  if USE_EVENT_LOG
    acts_as_activity_logged(:models => { :culprit => { :model => :submitter } })
  end

  # ===============
  # The :constrained_options field is a serialised array of values.
  # (See: http://www.salsaonrails.eu/2009/01/02/hash-serialization-in-an-activerecord-model for info)
  # ---------------

  serialize :constrained_options, Array

  def after_initialize
    self.constrained_options ||= [ ]
  end

  # ===============

  # get all the WmsMethodParameters that use this WmsParameter
  def wms_method_parameters
    WmsMethodParameter.find_all_by_wms_parameter_id(self.id)
  end

  # For the given wms_method object, find duplicate entry based on 'param_name'
  def self.check_duplicate(wms_method, param_name, search_local_context=false)
    p = wms_method.request_parameters.first(
        :conditions => {:name => param_name,
                        :is_global => !search_local_context})

    return p # WmsParameter || nil
  end

  # Check that a given param exists for the given wms_service object
  def self.check_exists_for_wms_service(wms_service, param_name, search_local_context=false)
    param = nil

    wms_service.wms_resources.each do |resource|
      resource.wms_methods.each { |method|
        param = WmsParameter.check_duplicate(method, param_name, search_local_context)
        break unless param.nil?
      }
      break unless param.nil?
    end

    return param # WmsParameter || nil
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
        "wms_parameter" => {
            "name" => self.name,
            "description" => self.preferred_description,
            "param_style" => self.param_style,
            "computational_type" => self.computational_type,
            "default_value" => self.default_value,
            "is_optional" => !self.required,
            "constrained_values" => self.constrained_options.reject { |x| x.blank? },
            "submitter" => BioCatalogue::Api.uri_for_object(self.submitter),
            "created_at" => self.created_at.iso8601,
            "archived_at" => self.archived? ? self.archived_at.iso8601 : nil
        }
    }

    unless make_inline
      data["wms_parameter"]["self"] = BioCatalogue::Api.uri_for_object(self)
      return data.to_json
    else
      data["wms_parameter"]["resource"] = BioCatalogue::Api.uri_for_object(self)
      return data["wms_parameter"].to_json
    end
  end # generate_json_and_make_inline

end
