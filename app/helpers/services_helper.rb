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
  
  def all_name_annotations_for_service(service)
    BioCatalogue::Annotations.all_name_annotations_for_service(service)
  end
  
  def service_type_badges(service_types)
    html = ''

    unless service_types.blank?
      service_types.each do |s_type|
        html << link_to(s_type, generate_include_filter_url(:t, s_type), :class => "service_type_badge", :style => "vertical-align: middle; margin-left: 1.5em;")
      end
    end

    return html
  end

  def service_location_flags(service)
    return '' if service.nil?

    html = ''

    service.service_deployments.each do |s_d|
      unless s_d.country.blank?
        html = html + flag_icon_from_country(s_d.country, :text => s_d.location, :class => "framed")
      end
    end

    return html
  end
end
