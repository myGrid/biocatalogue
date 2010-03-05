# BioCatalogue: app/views/services/api/_variants.xml.builder
#
# Copyright (c) 2009-2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# <variants>
parent_xml.tag! "variants",
                xlink_attributes(uri_for_object(service, :sub_path => "variants")),
                :resourceType => "Service" do 
    
  service.service_versions.each do |service_version|
    
    render :partial => "#{service_version.service_versionified.class.name.underscore.pluralize}/api/inline_item", 
           :locals => { :parent_xml => parent_xml, service_version.service_versionified.class.name.underscore.to_sym => service_version.service_versionified }
    
  end
  
end