# BioCatalogue: app/models/observers/annotation_observer.rb
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.

class AnnotationObserver < ActiveRecord::Observer
  
  include BioCatalogue::CacheHelper::Expires
  
  def after_create(annotation)
    expire_caches_for_tag_clouds(annotation)
    expire_caches_for_categories(annotation)
  end
  
  def after_update(annotation)
    expire_caches_for_tag_clouds(annotation)
    expire_caches_for_categories(annotation)
  end
  
  def after_destroy(annotation)
    expire_caches_for_tag_clouds(annotation)
    expire_caches_for_categories(annotation)
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
  
  def expire_caches_for_categories(annotation)
    if annotation.attribute_name.downcase == "category"
      reload_number_of_services_for_category_and_parents_caches(Category.find_by_id(annotation.value))
    end
  end
  
end