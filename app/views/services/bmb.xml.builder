# BioCatalogue: app/views/services/bmbs.xml.builder
#
# Copyright (c) 2009-2013, University of Manchester, The European Bioinformatics
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details


# <?xml>
xml.instruct! :xml

# <Tools>
xml.tag! "Tools" do
  @services.each_with_index do |service, index|
    xml.tag! "Tool", :toolid => "#{1000 + index}" do
      xml.tag! "ToolName", "#{service.name}\##{service.service.service_deployments.first.endpoint}"
      xml.tag! "Homepage", service.documentation_url
      xml.tag! "Type", "Service"
      categories = service.service.annotations.select { |ann| ann.value_type == "Category" }.collect { |cat| cat.value.name }
      xml.tag! "Topics" do
        categories.each do |category|
          xml.tag! "Topic", map_categories_to_edam_topics(category)
        end
      end
      #xml.tag! " #{SITE_NAME.camelize}URL", service_url(service.service)
      xml.tag! "Description", service.service.description ? service.description[0..200] : ""
      xml.tag! "Functions" do
        categories.each do |category|
          xml.tag! "Function", map_categories_to_edam_operations(category)
        end
      end
      xml.tag! "Interfaces", service.is_a?(RestService) ? "REST API" : "SOAP API"
      xml.tag! "DocsEntry", service.documentation_url
      xml.tag! "WSDL", service.try(:wsdl_location)
      xml.tag! "Helpdesk", ""
      xml.tag! "Source", "BioCatalogue"
      #inputType
      #outputType
    end
  end
end


=begin
Specs Given
---
Name
Homepage
Type (always "Service")
Topics (use original values mapping above)
Description
Functions (use mapping resolver above)
Interfaces (one of "REST API" or "SOAP API")
DocsEntry (maybe? - ask Alex / look)
WSDL
Helpdesk (don't think BC have this)
Source (always "BioCatalogue")
=end
