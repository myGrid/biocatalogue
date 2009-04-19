# BioCatalogue: app/helpers/services_helper.rb
#
# Copyright (c) 2008, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.

module ServicesHelper
  # Returns a hash with all the counts of the metadata pieces on a service,
  # grouped by the types of sources, as well as the total number of metadata pieces.
  #
  # This takes into account the entire service structure (ie: service container, 
  # service versions, service deployments, and the entire substructure of the service version instances). 
  #
  # NOTE (1): the notion of "metadata pieces" here is the combination of metadata stored in the database
  # (often gained from the service description docs) AND metadata stored as annotation through the Annotations plugin.
  # NOTE (2): to the user, "metadata pieces" and "annotations" are synonymous, but in the sytem these are different
  # but related concepts.
  #
  # The following keys are available in the hash:
  #  :total       - the total number of metadata pieces on this service (incl those in the db tables AND the Annotations plugin).
  #  :users       - the total number of annotations provided by users.
  #  :registries  - the total number of annotations that came from other registries.
  #  :providers   - the total number of annotations that came from the service providers (eg: from the service description docs).
  def metadata_counts_for_service(service)
    counts = { }
    
    return counts if service.nil?
    
    # :users
    # Made up of annotations, as well as some metadata stored in the db...
    
    users_count = total_number_of_annotations_for_service(service, "User")
    
    service.service_versions.each do |s_v|
      # Metadata of RestServices comes from users
      users_count += s_v.service_versionified.total_db_metadata_fields_count if s_v.service_versionified_type == "RestService"
    end
    
    counts[:users] = users_count
    
    # :registries
    counts[:registries] = total_number_of_annotations_for_service(service, "Registry")
    
    # :providers
    # Made up of annotations, as well as some metadata stored in the db...
    
    providers_count = total_number_of_annotations_for_service(service, "ServiceProvider")
    
    # For now only the metadata of SoapServices comes from a service description doc (ie: from a service provider)
    service.service_versions.each do |s_v|
      providers_count += s_v.service_versionified.total_db_metadata_fields_count if s_v.service_versionified_type == "SoapService"
    end
    
    counts[:providers] = providers_count
    
    # :total
    counts[:total] = counts.values.sum
    
    return counts
  end
  
  # Returns the number of annotations on a service by a specified source (or "all" for all sources).
  #
  # This takes into account the entire service structure (ie: service container, 
  # service versions, service deployments, and the entire substructure of the service version instances). 
  #
  # NOTE: this method ONLY takes into account annotations stored through the annotations plugin.
  def total_number_of_annotations_for_service(service, source_type="all")
    return 0 if service.nil?
    
    count = 0
    
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

  
  # ========================================
  # Faceting, filtering  and sorting helpers
  # ----------------------------------------

  # Gets all the service providers and their counts of services.
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
  
  # Gets all the different service types and their counts of services.
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
    params_dup = params.clone
    params_dup[:filter] = { }
    params_dup[:filter][filter_type] = filter_value
    
    return services_url(params_dup)
  end

  def generate_exclude_filter_url(filter_type, filter_value)
    
  end
  
  def generate_sort_url(sort_by, sort_order)
    params_dup = params.clone
    params_dup[:sortby] = sort_by.downcase
    params_dup[:sortorder] = sort_order.downcase
    
    return services_url(params_dup)
  end
  
  def is_sort_selected(sort_by, sort_order)
    return params[:sortby] == sort_by.downcase && params[:sortorder] == sort_order.downcase
  end
  
  # ========================================
end
