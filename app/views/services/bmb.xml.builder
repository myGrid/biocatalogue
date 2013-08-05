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
      xml.tag! "Type", service.is_a?(RestService) ? "REST Service" : "SOAP Service"
      #xml.tag! "#{SITE_NAME.camelize}URL", service_url(service.service)
      xml.tag! "Description", service.description ? service.description[0..200] : ""
      xml.tag! "WSDL",  service.try(:wsdl_location)
      xml.tag! "Documentation", service.documentation_url
    end
  end

end