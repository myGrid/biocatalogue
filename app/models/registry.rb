# BioCatalogue: app/models/registry.rb
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

class Registry < ActiveRecord::Base
  acts_as_trashable
  
  acts_as_annotation_source
  
  validates_presence_of :name
  validates_uniqueness_of :name
  
  before_create :generate_default_display_name
  
  def annotation_source_name
    self.display_name
  end
  
  private
  
  def generate_default_display_name
    self.display_name = self.name.humanize if self.display_name.blank?
  end
end
