class WmsMethodRepresentation < ActiveRecord::Base
  attr_accessible :created_at, :http_cycle, :id, :submitter_id, :submitter_type, :updated_at, :wms_method_id, :wms_representation_id

  if ENABLE_CACHE_MONEY
    is_cached :repository => $cache
    index :wms_method_id
    index :wms_representation_id
    index [ :wms_method_id, :http_cycle ]
    index [ :submitter_type, :submitter_id ]
  end

  if ENABLE_TRASHING
    acts_as_trashable
  end

  validates_presence_of :wms_method_id,
                        :wms_representation_id,
                        :http_cycle

  has_submitter

  validates_existence_of :submitter # User must exist in the db beforehand.

  if ENABLE_SEARCH
    searchable do
      text :submitter_name
    end
  end

  if USE_EVENT_LOG
    acts_as_activity_logged(:models => { :culprit => { :model => :submitter } })
  end

  belongs_to :wms_method

  belongs_to :wms_representation

  def associated_service_id
    @associated_service_id ||= BioCatalogue::Mapper.map_compound_id_to_associated_model_object_id(BioCatalogue::Mapper.compound_id_for(self.class.name, self.id), "Service")
  end

  def associated_service
    @associated_service ||= Service.find_by_id(associated_service_id)
  end

  def associated_wms_method_id
    self.wms_method_id
  end

  def associated_wms_method
    @associated_wms_method ||= WmsMethod.find_by_id(associated_wms_method_id)
  end
end
