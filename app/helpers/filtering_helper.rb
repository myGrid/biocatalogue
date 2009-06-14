# BioCatalogue: app/helpers/filtering_helper.rb
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.

# Filtering and sorting helpers

module FilteringHelper
  def help_text_for_filtering
    "You can build up a filtered list of services by selecting/deselecting the options below.<br/><br/>
    Filtering results will show services from all selected Providers.
    If you also select service types, the results will then be filtered to only show services of those type(s).<br/><br/>
    You can also just filter on service types alone."
  end
  
  def get_text_to_display_for_filter_value(filter_type, filter_value)
    return "" if filter_value.blank?
    
    text = filter_value
    
    is_ontology_term = false
    
    # Special processing for tags
    if [ :tag, :tag_s, :tag_ops, :tag_ins, :tag_outs ].include?(filter_type)
      base_uri, term = BioCatalogue::Tags.split_ontology_term_uri(text)
      text = term
      is_ontology_term = true unless base_uri.blank?
    end
    
    text = truncate(h(text), :length => 28)
    
    if is_ontology_term
    text = content_tag(:span, text, :class => 'ontology_term')
    end
    
    return text
  end
  
  def get_filters_all_cookie_key(filter_type_query_key)
    "filters_all_#{filter_type_query_key}".to_sym
  end
  
  def get_filters_all_cookie_value(filter_type_query_key)
    key = get_filters_all_cookie_key(filter_type_query_key)
    cookies[key]
  end
  
  # Note: this relies on the cookie functions defined in layouts/_head_tabber_html.erb
  def render_show_hide_links(filter_type_query_key, hidden_items_class)
    html = ""
    
    more_link_id = "more_link_#{filter_type_query_key}"
    less_link_id = "less_link_#{filter_type_query_key}"
    filters_all_cookie_key = get_filters_all_cookie_key(filter_type_query_key)
    filters_all_cookie_current_value = get_filters_all_cookie_value(filter_type_query_key)
    
    html << link_to_function("Show all" + expand_image("0.5em"), :id => more_link_id, :style => (filters_all_cookie_current_value == "true" ? "display:none;" : "")) do |page| 
      page.select(".#{hidden_items_class}").each do |el|
        el.toggle
      end
      page.toggle more_link_id, less_link_id
      page.call "setCookie", "#{filters_all_cookie_key}", "true"
    end
    
    html << link_to_function("Show top 10 only" + collapse_image("0.5em"), :id => less_link_id, :style => (filters_all_cookie_current_value == "true" ? "" : "display:none;")) do |page| 
      page.select(".#{hidden_items_class}").each do |el|
        el.toggle
      end
      page.toggle more_link_id, less_link_id
      page.call "setCookie", "#{filters_all_cookie_key}", "false"
      page << "$('#{more_link_id}').ancestors()[0].ancestors()[0].scrollTo();"
      page << "new Effect.Highlight($('#{more_link_id}').ancestors()[0].ancestors()[0], { duration: 1 });"
    end
    
    return html
  end
  
  def generate_include_filter_url(filter_type, filter_value)
    new_params = BioCatalogue::Filtering.add_filter_to_params(params, filter_type, filter_value)
    return services_url(new_params)
  end

  def generate_exclude_filter_url(filter_type, filter_value)
    new_params = BioCatalogue::Filtering.remove_filter_from_params(params, filter_type, filter_value)
    return services_url(new_params)
  end
  
  def is_filter_selected(filter_type, filter_value)
    return BioCatalogue::Filtering.is_filter_selected(params, filter_type, filter_value)
  end
  
  # Gets the current filters selected, in a grouped structure (Array of Hashes) to take into account subtypes...
  def current_selected_filters_grouped
    grouped = [ ]
    
    current_filters = BioCatalogue::Filtering.convert_params_to_filters(params)
    
    current_filters.each do |k,v|
      unless [ :su, :sr ].include?(k)
        grouped << { k => v }
      end
    end
    
    submitters = { }
    submitters[:su] = current_filters[:su] unless current_filters[:su].blank?
    submitters[:sr] = current_filters[:sr] unless current_filters[:sr].blank?
    
    grouped << submitters unless submitters.blank?
    
    return grouped
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
