# BioCatalogue: app/helpers/faceting_helper.rb
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.

# Faceting, filtering  and sorting helpers

module FacetingHelper
  def help_text_for_filtering
    "You can build up a filtered list of services by selecting/deselecting the options below.
    Filtering results will show services from all selected Providers.
    If you also select service types, the results will then be filtered to only show services of those type(s).
    You can also just filter on service types alone."
  end
  
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
    params_dup = BioCatalogue::Util.duplicate_params(params)
    params_dup[:f] = { } if params_dup[:f].nil?
    params_dup[:f][filter_type] = [ ] if params_dup[:f][filter_type].nil?
    params_dup[:f][filter_type] << filter_value
    
    # Reset page param
    params_dup.delete(:page)
    
    return "#{services_url(params_dup)}#browse"
  end

  def generate_exclude_filter_url(filter_type, filter_value)
    params_dup = BioCatalogue::Util.duplicate_params(params)
    unless params_dup[:f].nil? or params_dup[:f][filter_type].nil?
      params_dup[:f][filter_type].delete(filter_value)
    end
    
    # Reset page param
    params_dup.delete(:page)
    
    return "#{services_url(params_dup)}#browse"
  end
  
  def is_filter_selected(filter_type, filter_value)
    return params[:f] && params[:f][filter_type] && params[:f][filter_type].include?(filter_value)
  end
  
  def generate_sort_url(sort_by, sort_order)
    params_dup = BioCatalogue::Util.duplicate_params(params)
    params_dup[:sortby] = sort_by.downcase
    params_dup[:sortorder] = sort_order.downcase
      
    # Reset page param
    params_dup.delete(:page)
    
    return "#{services_url(params_dup)}#browse"
  end
  
  def is_sort_selected(sort_by, sort_order)
    return params[:sortby] == sort_by.downcase && params[:sortorder] == sort_order.downcase
  end
end
