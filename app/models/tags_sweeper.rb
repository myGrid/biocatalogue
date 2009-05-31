# BioCatalogue: app/models/tags_sweeper.rb
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.

class TagsSweeper < ActionController::Caching::Sweeper 
  
  include BioCatalogue::CacheHelper::Expires
  
  observe Annotation
  
  def after_create(annotation)
    expire_cache_for_tag_clouds(annotation)
  end
  
  def after_update(annotation)
    expire_cache_for_tag_clouds(annotation)
  end
  
  def after_destroy(annotation)
    expire_cache_for_tag_clouds(annotation)
  end
  
  protected
  
  def expire_cache_for_tag_clouds(annotation)
    if annotation.attribute_name.downcase == "tag"
      expire_service_index_tag_cloud
    end
  end
  
end