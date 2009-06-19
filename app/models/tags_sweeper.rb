# BioCatalogue: app/models/tags_sweeper.rb
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.

class TagsSweeper < ActionController::Caching::Sweeper 
  
  include BioCatalogue::CacheHelper::Expires
  
  observe Annotation
  
  def after_create(annotation)
    expire_caches_for_tag_clouds(annotation)
  end
  
  def after_update(annotation)
    expire_caches_for_tag_clouds(annotation)
  end
  
  def after_destroy(annotation)
    expire_caches_for_tag_clouds(annotation)
  end
  
  protected
  
  def expire_caches_for_tag_clouds(annotation)
    if annotation.attribute_name.downcase == "tag"
      
      # Service index tag cloud caches
      expire_service_index_tag_cloud
      
      # tags_flat caches
      
      expire_tags_flat(annotation.annotatable_type, annotation.annotatable_id)
      
      # Need to also take into account service's immediate sub structure
      if ([ "ServiceDeployment", "ServiceVersion" ] + BioCatalogue::Mapper::SERVICE_TYPE_ROOT_MODELS.map{|t| t.class.name}).include?(annotation.annotatable_type)
        expire_tags_flat(annotation.annotatable_type, BioCatalogue::Mapper.map_compound_id_to_associated_model_object_id("#{annotation.annotatable_type}:#{annotation.annotatable_id}", "Service"))
      end
      
    end
  end
  
end