# BioCatalogue: app/views/services/api/_monitoring.xml.builder
#
# Copyright (c) 2009-2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# <monitoring>
parent_xml.tag! "monitoring",
                xlink_attributes(uri_for_object(service, :sub_path => "monitoring")),
                :resourceType => "Service" do
  
  # <tests>
  parent_xml.tests do 
    
    service.service_tests.each do |service_test|
      render :partial => "service_tests/api/inline_item", :locals => { :parent_xml => parent_xml, :service_test => service_test }
    end
    
  end
  
end