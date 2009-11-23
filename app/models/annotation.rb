# BioCatalogue: app/models/annotation.rb
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.

#=====
# This extends the Annotation model defined in the Annotations plugin.
#=====

require_dependency RAILS_ROOT + '/vendor/plugins/annotations/lib/app/models/annotation'

class Annotation < ActiveRecord::Base
#  if ENABLE_CACHE_MONEY
#    is_cached :repository => $cache
#    index :attribute_id, :limit => 5000, :buffer => 100
#    index [ :source_type, :source_id ], :limit => 5000, :buffer => 100
#    index [ :annotatable_type, :annotatable_id ], :limit => 5000, :buffer => 100
#  end

  #ralationship to list of its properties and their values
  
  has_many :annotation_properties, :dependent=>:destroy
  has_one :annotation_parsed_type, :dependent=>:destroy
  

  acts_as_trashable
  
  validate :check_category_annotation

   
  
  after_save :process_post_save_custom_logic
  
  if USE_EVENT_LOG
    acts_as_activity_logged :models => { :culprit => { :model => :source },
                                         :referenced => { :model => :annotatable } }
  end
  
  if ENABLE_SEARCH
    acts_as_solr(:fields => [ :value_for_solr, 
                              { :associated_service_id => :r_id },
                              { :associated_service_provider_id => :r_id },
                              { :associated_user_id => :r_id }, 
                              { :associated_registry_id => :r_id } ])
  end
  
  protected
  
  def value_for_solr
    val = ''
    
    case self.attribute_name.downcase
      when "category"
        val = Category.find_by_id(self.value.to_i).try(:name) || ""
      else
        val = self.value
    end
    
    return val
  end
  
  def check_category_annotation
    if self.attribute_name.downcase == "category"
      if Category.find_by_id(self.value).nil?
        self.errors.add_to_base("Please select a valid category")
      end
    end
    return true
  end
  
  def associated_service_id
    BioCatalogue::Mapper.map_compound_id_to_associated_model_object_id(BioCatalogue::Mapper.compound_id_for(self.class.name, self.id), "Service")
  end
  
  def associated_service_provider_id
    BioCatalogue::Mapper.map_compound_id_to_associated_model_object_id(BioCatalogue::Mapper.compound_id_for(self.class.name, self.id), "ServiceProvider")
  end
  
  def associated_user_id
    BioCatalogue::Mapper.map_compound_id_to_associated_model_object_id(BioCatalogue::Mapper.compound_id_for(self.class.name, self.id), "User")
  end
  
  def associated_registry_id
    BioCatalogue::Mapper.map_compound_id_to_associated_model_object_id(BioCatalogue::Mapper.compound_id_for(self.class.name, self.id), "Registry")
  end
  
  def process_post_save_custom_logic
    if self.attribute_name.downcase == 'display_name'
      # Find all other similar annotations that have the 'display_name' attribute and "downgrade" them to 'alternative_name'
      self.annotatable.annotations_with_attribute('display_name').each do |ann|
        if ann.id != self.id
          # These annotations are read only so fetch again to modify...
          ann2 = Annotation.find_by_id(ann.id)
          if ann2
            ann2.attribute_name = "alternative_name"
            ann2.save
          end
        end
      end
    end
  end
end