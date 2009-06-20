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
  
  acts_as_trashable
  
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
    acts_as_solr(:fields => [ :display_name, :description, :homepage ] )
  end
  
  def annotation_source_name
    self.display_name
  end
  
  private
  
  def generate_default_display_name
    self.display_name = self.name.humanize if self.display_name.blank?
  end
end
