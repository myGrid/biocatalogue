# BioCatalogue: app/models/registry.rb
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

class Registry < ActiveRecord::Base
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

  if ENABLE_SEARCH
    acts_as_solr(:fields => [ :name, :display_name, :description, :homepage ] )
  end
  
  def to_json
    {
      "registry" => {
        "self" => BioCatalogue::Api.uri_for_object(self),
        "name" => BioCatalogue::Util.display_name(self),
        "description" => self.preferred_description,
        "homepage" => self.homepage,
        "created_at" => self.created_at.iso8601
      }
    }.to_json
  end
  
  def preferred_description
    desc = self.description
        
    if desc.blank?
      desc = self.annotations_with_attribute("description").first.try(:value)
    end
    
    return desc
  end
  
  def annotation_source_name
    self.display_name
  end
  
  private
  
  def generate_default_display_name
    self.display_name = self.name.humanize if self.display_name.blank?
  end
end
