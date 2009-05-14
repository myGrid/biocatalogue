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
  def render_show_hide_links(facet_type_query_key, hidden_items_class)
    html = ""
    
    more_link_id = "more_link_#{facet_type_query_key}"
    less_link_id = "less_link_#{facet_type_query_key}"
    facets_all_cookie_key = get_facets_all_cookie_key(facet_type_query_key)
    facets_all_cookie_current_value = get_facets_all_cookie_value(facet_type_query_key)
    
    html << link_to_function("Show all" + expand_image("0.5em"), :id => more_link_id, :style => (facets_all_cookie_current_value == "true" ? "display:none;" : "")) do |page| 
      page.select(".#{hidden_items_class}").each do |el|
        el.toggle
      end
      page.toggle more_link_id, less_link_id
      page.call "setCookie", "#{facets_all_cookie_key}", "true"
    end
    
    html << link_to_function("Show top 10 only" + collapse_image("0.5em"), :id => less_link_id, :style => (facets_all_cookie_current_value == "true" ? "" : "display:none;")) do |page| 
      page.select(".#{hidden_items_class}").each do |el|
        el.toggle
      end
      page.toggle more_link_id, less_link_id
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
    new_params = BioCatalogue::Faceting.add_filter_to_params(params, filter_type, filter_value)
    return services_url(new_params)
  end

  def generate_exclude_filter_url(filter_type, filter_value)
    new_params = BioCatalogue::Faceting.remove_filter_to_params(params, filter_type, filter_value)
    return services_url(new_params)
  end
  
  def is_filter_selected(filter_type, filter_value)
    return BioCatalogue::Faceting.is_filter_selected(params, filter_type, filter_value)
  end
  
  def generate_sort_url(sort_by, sort_order)
    params_dup = BioCatalogue::Util.duplicate_params(params)
    params_dup[:sortby] = sort_by.downcase
    params_dup[:sortorder] = sort_order.downcase
      
    # Reset page param
    params_dup.delete(:page)
    
    return services_url(params_dup)
  end
  
  def is_sort_selected(sort_by, sort_order)
    return params[:sortby] == sort_by.downcase && params[:sortorder] == sort_order.downcase
  end
end
