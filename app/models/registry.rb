# BioCatalogue: app/models/registry.rb
#
# Copyright (c) 2009-2010, University of Manchester, The European Bioinformatics
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
  
  acts_as_annotatable :name_field => :display_name
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
    searchable do
       text :name, :display_name, :homepage, :description
    end
  end

  def to_inline_json
    self.to_json
  end

  def to_json
    generate_json_and_make_inline(false)
  end 
  
  def to_inline_json
    generate_json_and_make_inline(true)
  end

  def preferred_description
    desc = self.description
        
    if desc.blank?
      desc = self.annotations_with_attribute("description", true).first.try(:value_content)
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
  
  def generate_json_and_make_inline(make_inline)
    data = {
      "registry" => {
        "name" => BioCatalogue::Util.display_name(self),
        "description" => self.preferred_description,
        "homepage" => self.homepage,
        "created_at" => self.created_at.iso8601
      }
    }

    unless make_inline
      data["registry"]["self"] = BioCatalogue::Api.uri_for_object(self)
			return data.to_json
    else
      data["registry"]["resource"] = BioCatalogue::Api.uri_for_object(self)
			return data["registry"].to_json
    end
  end # generate_json_and_make_inline

end
