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

# <Tools>
xml.tag! "tools", :"xmlns"=>"http://biotoolsregistry.org", :"xmlns:xsi"=>"http://www.w3.org/2001/XMLSchema-instance", :"xsi:schemaLocation"=>"http://biotoolsregistry.org biotools-beta03.xsd" do
  @services.each_with_index do |service, index|
    # Generic service is meant by g_service. A service is either of the RestService class or the SoapService class.
    # g_service is the generic Service class common to both
    g_service = service.service

    xml.tag! "tool", :toolid => "#{1000 + index}" do
      xml.tag! "name", "#{service.name}"
      xml.tag! "homepage", "#{service.service_deployments.first.endpoint}"
      xml.tag! "version", g_service.latest_version.version
      xml.tag! "collectionName", "#{SITE_BASE_HOST}"
      xml.tag! "uses", ""
      xml.tag! "softwareType", "Web Service", :uri => 'http://www.ebi.ac.uk/swo/interface/SWO_9000051'
      xml.tag! "interfaces" do
        if service.is_a?(RestService)
          xml.tag! "interfaceType", "REST API", :uri => 'http://www.ebi.ac.uk/swo/interface/SWO_50000005'
          xml.tag! "docs", "http://www.restdoc.org/spec.html"
          xml.tag! "specificationURL", ""
          xml.tag! "specificationFormat", ""
        else
          xml.tag! "interfaceType", "SOAP API",  :uri => 'http://www.ebi.ac.uk/swo/interface/SWO_5000004'
          xml.tag! "docs", "http://www.w3.org/TR/soap/"
          xml.tag! "specificationURL", ""
          xml.tag! "specificationFormat", ""
        end
      end
      xml.tag! "description", g_service.description ? service.description : ""
      categories = g_service.annotations.select { |ann| ann.value_type == "Category" }.collect { |cat| cat.value.name }
      categories.each do |category|
        xml.tag! "topic", map_categories_to_edam_topics(category)
      end
      tags = service.annotations.select { |ann| ann.value_type == "Tag" }.collect { |cat| cat.value.name }
      if tags.empty?
        xml.tag! "tag", ""
      else
        tags.each do |tag|
          xml.tag! "tag", tag, :uri => ""
        end
      end


      # There are 2 ways we could be outputting our content (for Rest Services).
      # 1. Each tool as a RestService
      # 2. Each tool as a RestMethod
      # I have gone for 1 atm as it is easier and we are not sure what the BioRegistry
      # people are going to need but we might want to change to 2 as it would offer
      # them more information. If someone was to implement it as 2 here is a handy hint
      # on accessing input / output information;
      #
      # rest_methods = RestMethod.find(141)
      # input_format = rest_methods.request_representations
      # output_format = rest_methods.response_representations

      xml.tag! "function" do
        categories.each do |category|
          operation = map_categories_to_edam_operations(category)
          if operation.nil?
             xml.tag! "functionName", operation.fetch(:name), :uri => operation.fetch(:uri)
            else
              xml.tag! "functionName", operation.fetch(:name), :uri => operation.fetch(:uri)
          end
        end
        xml.tag! "functionDescription" ""
        xml.tag! "functionHandle", ""
        xml.tag! "input" do
            xml.tag! "dataType", ""
            xml.tag! "dataFormat", ""
            xml.tag! "dataFormat", ""
            xml.tag! "dataHandle", ""
        end
        xml.tag! "output" do
            xml.tag! "dataType", ""
            xml.tag! "dataFormat", ""
            xml.tag! "dataFormat", ""
            xml.tag! "dataHandle", ""
        end
      end

      # Contact is free text - we could extract through regexp numbers and emails.
      # A brief look at all contact fields (by running: Service.all.each.select {|x| a << x.list_of("contact") }
      # shows that contact info is pretty hetrogeneous - lots of the time it points to a webpage though.
      g_service.list_of("contact").each do |c|
        xml.tag! "contact" do
          xml.tag! "email", c
          xml.tag! "name", ""
          xml.tag! "tel", ""
          xml.tag! "role", ""
        end
      end

      xml.tag! "registrant" do
        if (submitter = g_service.submitter).class == Registry
          xml.tag! "email", submitter.homepage
          xml.tag! "name", submitter.display_name
          xml.tag! "tel", ""
          xml.tag! "role", ""
        else #else individual
          xml.tag! "email", submitter.email
          xml.tag! "name", submitter.display_name
          xml.tag! "tel", ""
          xml.tag! "role", ""
        end
      end

      xml.tag! "sourceRegistry", "#{SITE_BASE_HOST}"
      xml.tag! "maturity", ""
      xml.tag! "platform", ""
      xml.tag! "language", ""
      xml.tag! "license", g_service.list_of("license").first
      xml.tag! "cost", g_service.list_of("cost").first

      xml.tag! "docs" do
        xml.tag! "homepage", service.documentation_url
        xml.tag! "docsHome", ""
      end

      publications = g_service.list_of("publication")
      if publications.empty?
        xml.tag! "publications" do
          xml.tag! "publicationPrimaryID", ""
          xml.tag! "publicationOtherID", ""
        end
      else
        publications.each do |pub|
          xml.tag! "publications" do
            xml.tag! "publicationPrimaryID", pub
            xml.tag! "publicationOtherID", ""
          end
        end
      end
      xml.tag! "credits" do
        xml.tag! "developer", ""
      end
    end
  end
end