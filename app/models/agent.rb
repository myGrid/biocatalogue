# BioCatalogue: app/models/agent.rb
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

class Agent < ActiveRecord::Base
  if ENABLE_CACHE_MONEY
    is_cached :repository => $cache
    index :name
  end
  
  if ENABLE_TRASHING
    acts_as_trashable
  end
  
  acts_as_annotatable
  acts_as_annotation_source
  
  validates_presence_of :name
  validates_uniqueness_of :name
  
  before_create :generate_default_display_name
  
  has_many :services,
           :as => "submitter"
  
  if USE_EVENT_LOG
    acts_as_activity_logged
  end
  
  def annotation_source_name
    self.display_name
  end
  
  def preferred_description
    self.annotations_with_attribute("description").first.try(:value)
  end
  
  def annotated_service_ids
    service_ids = self.annotations_by.collect do |a|
      BioCatalogue::Mapper.map_compound_id_to_associated_model_object_id(BioCatalogue::Mapper.compound_id_for(a.annotatable_type, a.annotatable_id), "Service")      
    end
    service_ids.compact.uniq
  end
  
  private
  
  def generate_default_display_name
    self.display_name = self.name.humanize if self.display_name.blank?
  end
end
