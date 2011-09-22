# BioCatalogue: app/models/tag.rb
#
# Copyright (c) 2011, University of Manchester, The European Bioinformatics
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

class Tag < ActiveRecord::Base
  validates_presence_of :name,
                        :label
  
  validates_uniqueness_of :name
  
  acts_as_annotation_value :content_field => :name
  
  if USE_EVENT_LOG
    acts_as_activity_logged
  end
  
  def self.find_or_create_simple_tag(tag_name)
    self.find_or_create_by_name_and_label(tag_name, tag_name)
  end
  
end
