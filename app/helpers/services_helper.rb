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
end
