# BioCatalogue: app/helpers/filtering_helper.rb
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.

# Filtering and sorting helpers

module FilteringHelper
  include ApplicationHelper
  
  def help_text_for_filtering
    "You can build up a filtered list of services by selecting/deselecting and combining the options below.<br/><br/>" +
    "Filters within a filter type will be OR'ed and selections between filter types will be AND'ed.<br/><br/>" +
    "e.g: selecting 2 providers - 'ebi.ac.uk' and 'example.com, and the service type 'SOAP', and the location 'United Kingdom' " +
    " will retrieve all SOAP services that are from ebi.ac.uk and example.com and located in United Kingdom"
  end
  
  def get_text_to_display_for_filter_value(filter_type, filter_value)
    return "" if filter_value.blank?
    
    text = filter_value
    
    is_ontology_term = false
    
    # Special processing for tags
    if BioCatalogue::Filtering::TAG_FILTER_KEYS.include?(filter_type)
      base_uri, term = BioCatalogue::Tags.split_ontology_term_uri(text)
      text = term
      is_ontology_term = true unless base_uri.blank?
    end
    
    # Special processing for categories
    if filter_type == :cat
      c = Category.find_by_id(filter_value)
      text = (c.nil? ? "(Invalid category!)" : c.name)
    end
    
    text = truncate(h(text), :length => 32)
    
    if is_ontology_term
      text = content_tag(:span, text, :class => 'ontology_term')
    end
    
    return text
  end
  
  def get_tooltip_text_for_filter_value(filter_type, filter_value)
    case filter_type
      when :cat
        c = Category.find_by_id(filter_value)
        return (c.nil? ? "(Invalid category!)" : BioCatalogue::Categorising.category_hierachy_text(c))
      else
        return h(h(filter_value))
    end
  end
  
  def get_filters_all_cookie_key(filter_type_query_key)
    "filters_all_#{filter_type_query_key}".to_sym
  end
  
  def get_filters_all_cookie_value(filter_type_query_key)
    key = get_filters_all_cookie_key(filter_type_query_key)
    cookies[key]
  end
  
  # Note: this relies on the cookie functions defined in layouts/_head_tabber_html.erb
  def render_show_hide_filters_links(filter_type_query_key, hidden_items_class)
    html = ""
    
    more_text = ""
    less_text = ""
    case filter_type_query_key
      when :cat
        more_text = "Show subcategories"
        less_text = "Show top level categories only"
      else
        more_text = "Show all"
        less_text = "Show top 10 only"
    end
    
    more_link_id = "more_link_#{filter_type_query_key}"
    less_link_id = "less_link_#{filter_type_query_key}"
    filters_all_cookie_key = get_filters_all_cookie_key(filter_type_query_key)
    filters_all_cookie_current_value = get_filters_all_cookie_value(filter_type_query_key)
    
    html << link_to_function(more_text + expand_image("0.5em"), :id => more_link_id, :style => (filters_all_cookie_current_value == "true" ? "display:none;" : "")) do |page| 
      page.select(".#{hidden_items_class}").each do |el|
        el.toggle
      end
      page.toggle more_link_id, less_link_id
      page.call "setCookie", "#{filters_all_cookie_key}", "true"
    end
    
    html << link_to_function(less_text + collapse_image("0.5em"), :id => less_link_id, :style => (filters_all_cookie_current_value == "true" ? "" : "display:none;")) do |page| 
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
    return BioCatalogue::Filtering.is_filter_selected(@current_filters, filter_type, filter_value)
  end
  
  # Gets the current filters selected, in a grouped structure (Array of Hashes) to take into account subtypes...
  def current_selected_filters_grouped
    grouped = [ ]
    
    return grouped unless defined?(@current_filters) and !@current_filters.blank? 
    
    @current_filters.each do |k,v|
      unless [ :su, :sr ].include?(k)
        grouped << { k => v }
      end
    end
    
    submitters = { }
    submitters[:su] = @current_filters[:su] unless @current_filters[:su].blank?
    submitters[:sr] = @current_filters[:sr] unless @current_filters[:sr].blank?
    
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
  
  def show_tag_filters?
    params.has_key?(:tag_filters) && params[:tag_filters].downcase == "on"
  end
  
  def service_index_tag_filters_on_off_link
    output = ''
    
    params_dup = BioCatalogue::Util.duplicate_params(params)
    
    if show_tag_filters?
      text = "Disable tag filters"
      tooltip_text = "This will disable filtering by tags on services, operations, inputs and outputs. (This will likely improve the loading of this page)."
      params_dup.delete(:tag_filters)
      BioCatalogue::Filtering::TAG_FILTER_KEYS.each do |key|
        params_dup.delete(key)
      end
    else
      text = "Enable tag filters"
      tooltip_text = "This shows options to filter by tags on services, operations, inputs and outputs. (Note that this may cause slower loading of this page)."
      params_dup[:tag_filters] = "on"
    end
    
    url = services_path(params_dup)
    
    output << link_to(text, url, :class => "button_slim", :style => "font-size: 93%;", :title => tooltip_title_attrib(tooltip_text))
    
    return output
  end
end
