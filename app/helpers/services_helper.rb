# BioCatalogue: app/helpers/services_helper.rb
#
# Copyright (c) 2008, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.

module ServicesHelper
  def total_number_of_annotations_for_service(service, source_type="all")
    return 0 if service.nil?
    
    count = 0
    
    # TODO: take into account database fields that have metadata - these are essentially "provider" annotations.
    
    count += service.count_annotations_by(source_type)
    
    service.service_deployments.each do |s_d|
      count += s_d.count_annotations_by(source_type)
    end
    
    service.service_versions.each do |s_v|
      count += s_v.count_annotations_by(source_type)
      count += s_v.service_versionified.total_annotations_count(source_type)
    end
    
    return count
  end
  
  def all_name_annotations_for_service(service)
    annotations = [ ]
    
    annotations.concat(service.annotations_with_attribute("name"))
    
    service.service_deployments.each do |s_d|
      annotations.concat(s_d.annotations_with_attribute("name"))
    end
    
    service.service_versions.each do |s_v|
      annotations.concat(s_v.annotations_with_attribute("name"))
      annotations.concat(s_v.service_versionified.annotations_with_attribute("name"))
    end
    
    return annotations
  end

  
  # ============================
  # Facets and filtering helpers
  # ----------------------------
  
  # Example return data:
  # [ { "name" => "ebi.ac.uk", "count" => "12" }, { "name" => "example.com", "count" => "11" }, ... ]
  def get_facets_for_service_providers(limit=nil)
    # NOTE: this query has only been tested to work with MySQL 5.0.x
    sql = "SELECT service_providers.name AS name, COUNT(*) AS count 
          FROM service_providers 
          INNER JOIN service_deployments ON service_providers.id = service_deployments.service_provider_id 
          INNER JOIN services ON services.id = service_deployments.service_id 
          GROUP BY service_providers.id 
          ORDER BY COUNT(*) DESC"
    
    # If limit has been provided in the URL then add that to query.
    if !limit.nil? && limit.is_a?(Fixnum) && limit > 0
      sql += " LIMIT #{limit}"
    end
     
    return ActiveRecord::Base.connection.select_all(sql)
  end
  
  # Example return data:
  # [ { "name" => "SOAP", "count" => "102" }, { "name" => "REST", "count" => "11" }, ... ]
  def get_facets_for_service_types(limit=nil)
    facets = { }
    
    # NOTE: this query has only been tested to work with MySQL 5.0.x
    sql = "SELECT service_versions.service_versionified_type AS name, COUNT(*) AS count 
          FROM service_versions 
          INNER JOIN services ON services.id = service_versions.service_id 
          GROUP BY service_versions.service_versionified_type 
          ORDER BY COUNT(*) DESC"
    
    # If limit has been provided in the URL then add that to query.
    if !limit.nil? && limit.is_a?(Fixnum) && limit > 0
      sql += " LIMIT #{limit}"
    end
     
    facets = ActiveRecord::Base.connection.select_all(sql)
    
    # Need to "massage" the returned data...
    
    facets.each do |f|
      f["name"] = f["name"].constantize.new.service_type_name
    end
    
    return facets
  end
  
  def generate_include_filter_url(filter_type, filter_value)
    
  end

  def generate_exclude_filter_url(filter_type, filter_value)
    
  end
  
  # ============================
end
