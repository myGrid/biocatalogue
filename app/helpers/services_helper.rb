# BioCatalogue: app/helpers/services_helper.rb
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.

module ServicesHelper
  def metadata_counts_for_service(service)
    BioCatalogue::Annotations.metadata_counts_for_service(service)
  end
  
  def total_number_of_annotations_for_service(service, source_type="all")
    BioCatalogue::Annotations.total_number_of_annotations_for_service(service, source_type)
  end
  
  def all_alternative_name_annotations_for_service(service)
    BioCatalogue::Annotations.annotations_for_service_by_attribute(service, "alternative_name")
  end
  
  def service_type_badges(service_types)
    html = ''

    unless service_types.blank?
      service_types.each do |s_type|
        if s_type == "Soaplab"
          html << content_tag(:span, s_type, :class => "service_type_badge_special", :style => "vertical-align: middle; margin-left: 1.5em;")
        else
          html << link_to(s_type, services_path(:t => "[#{s_type}]"), :class => "service_type_badge", :style => "vertical-align: middle; margin-left: 1.5em;")  
        end
      end
    end

    return html
  end

  def service_location_flags(service)
    return '' if service.nil?

    html = ''

    service.service_deployments.each do |s_d|
      unless s_d.country.blank?
        html << link_to(flag_icon_from_country(s_d.country, :text => s_d.location, :style => 'vertical-align: middle; margin-left: 0.5em;'), 
                        services_path(:c => "[#{s_d.country}]"), 
                        :class => "service_location_flag")
      end
    end

    return html
  end
  
  def render_computational_type_details(details_hash)
    return "" if details_hash.blank?
    return details_hash.to_s if (!details_hash.is_a?(Hash) and !details_hash.is_a?(Array))
    
    logger.info("computational type details class = #{details_hash.class.name}")
    
    return render_computational_type_details_entries([ details_hash['type'] ].flatten)
  end
  
  # Only services that have an associated soaplab server
  # are updated.
  def render_description_from_soaplab(soap_service)
    if soap_service.soaplab_service?
      from_hash_to_html(soap_service.description_from_soaplab)
    end
  end
  
  def render_description_from_soaplab_snippet(soap_service)
    if soap_service.soaplab_service?
      from_hash_to_html(soap_service.description_from_soaplab, 3)
    end
  end
  
  protected
  
  def render_computational_type_details_entries(entries)
    html = ''
    
    return html if entries.empty?
    
    html << content_tag(:ul) do
      x = ''
      entries.each do |entry|
        x << render_computational_type_details_entry(entry)
      end
      x
    end
    
    return html
  end
  
  def render_computational_type_details_entry(entry)
    html = ''
    
    return html if entry.blank?
    
    html << content_tag(:li) do
      x = entry['name']
      if entry['documentation']
        x << info_icon_with_tooltip(white_list(simple_format(entry['documentation'])))
      end
      if entry['type'] and !entry['type'].blank?
        x << content_tag(:span, "type:", :class => "type_keyword")
        x << render_computational_type_details_entries([ entry['type'] ].flatten)
      end
      x
    end
    
    return html
  end
  
  def get_sorted_list_of_service_ids_from_metadata_counts(service_metadata_counts)
    results = [ ]
    
    return results if service_metadata_counts.blank?
    
    results = service_metadata_counts.keys.sort { |a,b| service_metadata_counts[b][:all] <=> service_metadata_counts[a][:all] }
    
    return results
  end
  

  # convert to an html nested list
  def from_hash_to_html(dict, depth_to_traverse=1000, start_depth=0)
    depth = start_depth
    if dict.is_a?(Hash) && !dict.empty?
      str =''
      str << '<ul>'
      depth += 1
      dict.each do |key, value|
        unless depth > depth_to_traverse
          out = ""
          case value
            when String
              out << value
            when Array
              value.each do |v|
                out << v if v.is_a?(String) 
                out << from_hash_to_html(v, depth_to_traverse, depth) if v.is_a?(Hash)
              end
            end 
          str << "<li> #{key}  : #{ out }</li> "
          if value.is_a?(Hash) 
            str << from_hash_to_html(value, depth_to_traverse, depth)
          end
        end
      end
      str << '</ul> '
      return str
    end
    return ''
  end
  
end
