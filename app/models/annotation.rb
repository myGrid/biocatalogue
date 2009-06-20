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

  acts_as_trashable
  
  validate :check_category_annotation
  
  if USE_EVENT_LOG
    acts_as_activity_logged :models => { :culprit => { :model => :source },
                                         :referenced => { :model => :annotatable } }
  end
  
  if ENABLE_SEARCH
    acts_as_solr(:fields => [ :value_for_solr ] )
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
end