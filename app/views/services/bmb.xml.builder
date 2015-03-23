# BioCatalogue: app/views/services/bmbs.xml.builder
#
# Copyright (c) 2009-2013, University of Manchester, The European Bioinformatics
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details


# BioCatalogue: app/views/services/bmbs.xml.builder
#
# Copyright (c) 2009-2013, University of Manchester, The European Bioinformatics
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

#

# <?xml>
xml.instruct! :xml


count_for = {}
count_for['rest_services'] = 0
count_for['soap_services'] = 0
count_for['excluded'] = 0
debug_mode = false


xml.tag! "resources", :"xmlns" => "http://biotoolsregistry.org",
         :"xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance",
         :"xsi:schemaLocation" => "http://biotoolsregistry.org biotools-1.0.xsd" do



  #set services to @services for full list
  @services.each_with_index do |service, index|
    if service[:valid]
      unless debug_mode
        #xml.tag! "resource", :toolid => "#{1000 + index}" do
        xml.tag! "resource" do
          xml.tag! "name", "#{service[:service].name}"
          xml.tag! "homepage", service[:homepage]
          xml.tag! "resourceType", "Tool"
          xml.tag! "interface" do
            if service[:service].is_a?(RestService)
              xml.tag! "interfaceType", "REST API", :uri => 'http://www.ebi.ac.uk/swo/interface/SWO_50000005'
              count_for['rest_services'] += 1
            else
              xml.tag! "interfaceType", "SOAP WS", :uri => 'http://www.ebi.ac.uk/swo/interface/SWO_5000004'
              count_for['soap_services'] += 1
            end
          end

          xml.tag! "description", service[:service].annotations_with_attribute('elixir_description').first.value.text

          service[:edam_topics].each do |topic|
            xml.tag! "topic", topic.last[:name], :uri => topic.last[:uri]
          end
          tags = service[:service].annotations.select { |ann| ann.value_type == "Tag" }.collect { |cat| cat.value.name }
          unless tags.empty?
            tags.each do |tag|
              xml.tag! "tag", tag
            end
          end
          xml.tag! "function" do
            service[:edam_operations].each do |operation|
                xml.tag! "functionName", operation.last.fetch(:name), :uri => operation.last.fetch(:uri)
              end
            end

        xml.tag! "contactDetails" do
          if service[:contact_url].nil?
            xml.tag! "contactEmail", service[:contact_email]
          else
            xml.tag! "contactURL", service[:contact_url]
          end
        end
        xml.tag! "sourceRegistry", "#{service_url(service[:service])}"
        xml.tag! "docs" do
          xml.tag! "docsHome", service[:homepage]
        end
      end
          end

    else
      if debug_mode
        count_for['excluded'] += 1
        xml.tag! 'DEBUG' do
          xml.tag! 'instanceofservice', service[:service].inspect
          xml.tag! 'service', service[:g_service].inspect
          xml.tag! 'ops', service[:edam_operations]
          xml.tag! 'tops', service[:edam_topics]
          xml.tag! 'desc', service[:g_service].preferred_description
          xml.tag! 'arch', service[:g_service].archived?
          xml.tag! 'con-url', service[:contact_url]
          xml.tag! 'con-email', service[:contact_email]
          xml.tag! 'doc_page', service[:service].service.list_of("documentation_url")
          xml.tag! 'homepage', service[:homepage]
        end
      end
    end
  end
  if debug_mode
    xml.tag! "rest", "Eligible REST Services = #{count_for['rest_services']}"
    xml.tag! "soap", "Eligible SOAP Services = #{count_for['soap_services']}"
    xml.tag! "exc", "Services Excluded = #{count_for['excluded']} / #{@services.count}"
  end
end
