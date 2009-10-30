# BioCatalogue: app/views/services/api/_versions.xml.builder
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

parent_xml.versions xlink_attributes(uri_for_object(service, :sub_path => "versions")) do 
    
  service.service_versions.each do |service_version|
    
    # <version>
    parent_xml.version xlink_attributes(uri_for_object(service_version)),
                :versionNumber => service_version.version,
                :versionNumberDisplayText => service_version.version_display_text do 
      
      # <instance>
      parent_xml.instance xlink_attributes(uri_for_object(service_version.service_versionified), :title => xlink_title(service_version.service_versionified)),
                   :serviceType => service_version.service_versionified.service_type_name do
        parent_xml.name service_version.service_versionified.name
      end
      
      # <submitter>
      parent_xml.submitter xlink_attributes(uri_for_object(service_version.submitter), :title => xlink_title(service_version.submitter)), 
                    :submitterType => service_version.submitter_type do
        parent_xml.name service_version.submitter_name
      end
      
    end
    
  end
  
end