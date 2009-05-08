# BioCatalogue: app/helpers/faceting_helper.rb
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.

# Faceting, filtering  and sorting helpers

module FacetingHelper
  def help_text_for_filtering
    "You can build up a filtered list of services by selecting/deselecting the options below.<br/><br/>
    Filtering results will show services from all selected Providers.
    If you also select service types, the results will then be filtered to only show services of those type(s).<br/><br/>
    You can also just filter on service types alone."
  end
  
  def get_facets_all_cookie_key(facet_type_query_key)
    "facets_all_#{facet_type_query_key}".to_sym
  end
  
  def get_facets_all_cookie_value(facet_type_query_key)
    key = get_facets_all_cookie_key(facet_type_query_key)
    cookies[key]
  end
  
  # Note: this relies on the cookie functions defined in layouts/_head_tabber_html.erb
  def render_show_hide_links(facet_type_query_key, all_facets_id, top_facets_id)
    html = ""
    
    more_link_id = "more_link_#{facet_type_query_key}"
    less_link_id = "less_link_#{facet_type_query_key}"
    facets_all_cookie_key = get_facets_all_cookie_key(facet_type_query_key)
    facets_all_cookie_current_value = get_facets_all_cookie_value(facet_type_query_key)
    
    html << link_to_function("Show all" + expand_image("0.5em"), :id => more_link_id, :style => (facets_all_cookie_current_value == "true" ? "display:none;" : "")) do |page| 
      page.toggle more_link_id, less_link_id, all_facets_id, top_facets_id
      page.call "setCookie", "#{facets_all_cookie_key}", "true"
    end
    
    html << link_to_function("Show top 10 only" + collapse_image("0.5em"), :id => less_link_id, :style => (facets_all_cookie_current_value == "true" ? "" : "display:none;")) do |page| 
      page.toggle more_link_id, less_link_id, all_facets_id, top_facets_id
      page.call "setCookie", "#{facets_all_cookie_key}", "false"
    end
    
    return html
  end
  
  def get_facets_for_service_providers(limit=nil)
    BioCatalogue::Faceting.get_facets_for_service_providers(limit)
  end
  
  def get_facets_for_service_types(limit=nil)
    BioCatalogue::Faceting.get_facets_for_service_types(limit)
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
