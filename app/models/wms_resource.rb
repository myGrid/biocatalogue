class WmsResource < ActiveRecord::Base
  attr_accessible :archived_at, :created_at, :description, :id, :parent_resource_id, :path, :submitter_id, :submitter_type, :updated_at, :wms_service_id

  if ENABLE_CACHE_MONEY
    is_cached :repository => $cache
    index :wms_service_id
    index :parent_resource_id
    index [ :submitter_type, :submitter_id ]
  end

  has_submitter

  validates_existence_of :submitter # User must exist in the db beforehand.

  if ENABLE_TRASHING
    acts_as_trashable
  end

  acts_as_annotatable :name_field => :path

  acts_as_archived

  validates_presence_of :wms_service_id,
                        :path

  belongs_to :wms_service

  belongs_to :parent_resource,
             :class_name => "WmsResource",
             :foreign_key => "parent_resource_id"

  has_many :wms_methods,
           :dependent => :destroy,
           :include => [ :wms_method_parameters, :wms_method_representations ],
           :conditions => "wms_methods.archived_at IS NULL",
           :order => "wms_methods.method_type ASC"

  has_many :archived_wms_methods,
           :class_name => "WmsMethod",
           :foreign_key => "wms_resource_id",
           :dependent => :destroy,
           :include => [ :wms_method_parameters, :wms_method_representations ],
           :conditions => "wms_methods.archived_at IS NOT NULL",
           :order => "wms_methods.method_type ASC"

  if ENABLE_SEARCH
    searchable do
      text :description, :path, :submitter_name
    end
  end

  if USE_EVENT_LOG
    acts_as_activity_logged(:models => {:referenced => { :model => :wms_service },
                                        :culprit => { :model => :submitter }})
  end

  # For the given wms_service object, find duplicate entry based on 'resource_path'
  def self.check_duplicate(wms_service, resource_path)
    return wms_service.wms_resources(true).find_by_path(resource_path) # WmsResource || nil
  end

  # for sort
  def <=>(other)
    return self.path <=> other.path
  end

  def display_name
    self.path
  end

  # This returns an Array of Hashes that has the grouped and sorted wms_methods of this .
  #
  # Example output:
  #   [ { :group_name => "..", :items => [ ... ] }, { :group_name => "..", :items => [ ... ] }  ]
  def wms_methods_grouped
    return WmsMethod.group_wms_methods(self.wms_methods)
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
        "wms_resource" => {
            "path" => self.path,
            "submitter" => BioCatalogue::Api.uri_for_object(self.submitter),
            "created_at" => self.created_at.iso8601,
            "archived_at" => self.archived? ? self.archived_at.iso8601 : nil
        }
    }

    unless make_inline
      data["wms_resource"]["methods"] = BioCatalogue::Api::Json.collection(self.wms_methods)
      data["wms_resource"]["self"] = BioCatalogue::Api.uri_for_object(self)
      return data.to_json
    else
      data["wms_resource"]["resource"] = BioCatalogue::Api.uri_for_object(self)
      return data["wms_resource"].to_json
    end
  end # generate_json_and_make_inline
end
