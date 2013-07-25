# BioCatalogue: app/models/rest_method_representation.rb
#
# Copyright (c) 2009-2010, University of Manchester, The European Bioinformatics
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

class RestMethodRepresentation < ActiveRecord::Base
  if ENABLE_CACHE_MONEY
    is_cached :repository => $cache
    index :rest_method_id
    index :rest_representation_id
    index [ :rest_method_id, :http_cycle ]
    index [ :submitter_type, :submitter_id ]
  end
  
  if ENABLE_TRASHING
    acts_as_trashable
  end

  validates_presence_of :rest_method_id,
                        :rest_representation_id,
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

  belongs_to :rest_method
  
  belongs_to :rest_representation
  
  def associated_service_id
    @associated_service_id ||= BioCatalogue::Mapper.map_compound_id_to_associated_model_object_id(BioCatalogue::Mapper.compound_id_for(self.class.name, self.id), "Service")
  end
  
  def associated_service
    @associated_service ||= Service.find_by_id(associated_service_id)
  end

  def associated_rest_method_id
    self.rest_method_id
  end
  
  def associated_rest_method
    @associated_rest_method ||= RestMethod.find_by_id(associated_rest_method_id)
  end
end
