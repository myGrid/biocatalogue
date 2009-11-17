# BioCatalogue: app/models/observers/annotation_observer.rb
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.

class AnnotationObserver < ActiveRecord::Observer
  
  include BioCatalogue::CacheHelper::Expires
  
  def after_create(annotation)
    expire_caches(annotation)
  end
  
  def after_update(annotation)
    expire_caches(annotation)
  end
  
  def after_destroy(annotation)
    expire_caches(annotation)
  end
  
  protected
  
  def expire_caches(annotation)
    
    attrib_name = annotation.attribute_name.downcase
    
    # Tag clouds
    if attrib_name == "tag"
      
      # Service index tag cloud cache
      expire_service_index_tag_cloud
      
      # annotations tags_flat cache
      model_names = [ "Service", "ServiceDeployment", "ServiceVersion" ] + BioCatalogue::Mapper::SERVICE_TYPE_ROOT_MODELS.map{|t| t.name}
      if model_names.include?(annotation.annotatable_type)
        compound_id = BioCatalogue::Mapper.compound_id_for(annotation.annotatable_type, annotation.annotatable_id)
        parent_service_id = BioCatalogue::Mapper.map_compound_id_to_associated_model_object_id(compound_id, "Service")
        expire_annotations_tags_flat_partial(annotation.annotatable_type, parent_service_id)
      end
      
    end
    
    # Categories
    if attrib_name == "category"
      reload_number_of_services_for_category_and_parents_caches(Category.find_by_id(annotation.value))
      
      # ... in service listing
      expire_categories_in_service_listing(annotation.annotatable_id) if annotation.annotatable_type == "Service"
    end
    
    # Name aliases
    if attrib_name == "alternative_name"
      # ... in service listing
      model_names = [ "Service", "ServiceDeployment", "ServiceVersion" ] + BioCatalogue::Mapper::SERVICE_TYPE_ROOT_MODELS.map{|t| t.name}
      if model_names.include?(annotation.annotatable_type)
        compound_id = BioCatalogue::Mapper.compound_id_for(annotation.annotatable_type, annotation.annotatable_id)
        parent_service_id = BioCatalogue::Mapper.map_compound_id_to_associated_model_object_id(compound_id, "Service")
        expire_name_aliases_in_service_listing(parent_service_id)
      end
    end
    
    # Descriptions
    if attrib_name == "description"
      # ... in service listing
      model_names = [ "Service", "ServiceDeployment", "ServiceVersion" ] + BioCatalogue::Mapper::SERVICE_TYPE_ROOT_MODELS.map{|t| t.name}
      if model_names.include?(annotation.annotatable_type)
        compound_id = BioCatalogue::Mapper.compound_id_for(annotation.annotatable_type, annotation.annotatable_id)
        parent_service_id = BioCatalogue::Mapper.map_compound_id_to_associated_model_object_id(compound_id, "Service")
        expire_descriptions_in_service_listing(parent_service_id)
      end
    end
    
  end
  
end