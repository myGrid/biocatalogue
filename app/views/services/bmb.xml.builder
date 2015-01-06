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

#services = @services[1..50]
# <Tools>
xml.tag! "resources", :"xmlns"=>"http://biotoolsregistry.org",
         :"xmlns:xsi"=>"http://www.w3.org/2001/XMLSchema-instance",
         :"xsi:schemaLocation"=>"http://biotoolsregistry.org biotools-beta08.xsd" do
  @services.each_with_index do |service, index|

    # Generic service is meant by g_service. A service is either of the RestService class or the SoapService class.
    # g_service is the generic Service class common to both
    g_service = service.service
    categories = g_service.annotations.select { |ann| ann.value_type == "Category" }.collect { |cat| cat.value.name }
    #map cats to edam topics
    edam_topics = []
    categories.each{|x| edam_topics << map_categories_to_edam_topics(x)}
    edam_topics.uniq!

    operations = []
    categories.each{|x| operations << map_categories_to_edam_operations(x)}
    operations.reject!{|c| c.empty?}
    operations.uniq!

    valid = !operations.empty? &&
        !edam_topics.empty? &&
        !g_service.description.nil?

    if valid
      #xml.tag! "resource", :toolid => "#{1000 + index}" do
      xml.tag! "resource" do
        xml.tag! "name", "#{service.name}"
        xml.tag! "homepage", "#{service_url(service)}"#{service.service_deployments.first.endpoint}
        xml.tag! "version", g_service.latest_version.version
        #xml.tag! "collectionName", "#{SITE_BASE_HOST}"
        #xml.tag! "uses", ""
        #xml.tag! "softwareType", "Web Service", :uri => 'http://www.ebi.ac.uk/swo/interface/SWO_9000051'
        xml.tag! "resourceType", "Other"#, :uri => 'http://www.ebi.ac.uk/swo/interface/SWO_9000051'
        xml.tag! "interface" do
          if service.is_a?(RestService)
            xml.tag! "interfaceType", "REST API", :uri => 'http://www.ebi.ac.uk/swo/interface/SWO_50000005'
            xml.tag! "interfaceDocs", "http://www.restdoc.org/spec.html"
            #xml.tag! "interfaceSpecURL", ""
            #xml.tag! "specificationFormat", ""
          else
            xml.tag! "interfaceType", "SOAP WS",  :uri => 'http://www.ebi.ac.uk/swo/interface/SWO_5000004'
            xml.tag! "interfaceDocs", "http://www.w3.org/TR/soap/"
            #xml.tag! "interfaceSpecURL", ""
            #xml.tag! "specificationFormat", ""
          end
        end
        xml.tag! "description", g_service.description ? truncate(service.description, length: 1000) : ""

        edam_topics.each do |topic|
          xml.tag! "topic", topic[:name], :uri => topic[:uri]
        end
        tags = service.annotations.select { |ann| ann.value_type == "Tag" }.collect { |cat| cat.value.name }
        if tags.empty?
          #xml.tag! "tag", ""
        else
          tags.each do |tag|
            xml.tag! "tag", tag
          end
        end


        # There are 2 ways we could be outputting our content (for Rest Services).
        # 1. Each tool as a RestService
        # 2. Each tool as a RestMethod
        # I have gone for 1 at present as it is easier and we are not sure what the BioRegistry
        # people are going to need but we might want to change to 2 as it would offer
        # them more information. If someone was to implement it as 2 here is a handy hint
        # on accessing input / output information;
        #
        # rest_methods = RestMethod.find(141)
        # input_format = rest_methods.request_representations
        # output_format = rest_methods.response_representations

        xml.tag! "function" do
          operations.each do |operation|
            if operation.nil?
               xml.tag! "functionName", operation.fetch(:name), :uri => operation.fetch(:uri)
              else
                xml.tag! "functionName", operation.fetch(:name), :uri => operation.fetch(:uri)
            end
          end
          #xml.tag! "functionDescription" ""
          #xml.tag! "functionHandle", ""
          #xml.tag! "input" do
          #    xml.tag! "dataType", ""
          #    xml.tag! "dataFormat", ""
          #    xml.tag! "dataFormat", ""
          #    xml.tag! "dataHandle", ""
          #end
          #xml.tag! "output" do
          #    xml.tag! "dataType", ""
          #    xml.tag! "dataFormat", ""
          #    xml.tag! "dataFormat", ""
          #    xml.tag! "dataHandle", ""
          #end
        end

        # Contact is free text - we could extract through regexp numbers and emails.
        # A brief look at all contact fields (by running: Service.all.each.select {|x| a << x.list_of("contact") }
        # shows that contact info is pretty hetrogeneous - lots of the time it points to a webpage though.
=begin
        g_service.list_of("contact").each do |c|
          xml.tag! "contact" do
            xml.tag! "email", c
            #xml.tag! "name", ""
            #xml.tag! "tel", ""
            #xml.tag! "role", ""
          end
        end
=end

        xml.tag! "contact" do
          if (submitter = g_service.submitter).class == Registry
            xml.tag! "contactEmail", submitter.homepage
            xml.tag! "contactName", submitter.display_name
     #       xml.tag! "tel", ""
     #       xml.tag! "role", ""
          else #else individual
            xml.tag! "contactEmail", submitter.email
            xml.tag! "contactName", submitter.display_name
     #       xml.tag! "tel", ""
     #       xml.tag! "role", ""
          end
        end

        xml.tag! "sourceRegistry", "#{SITE_BASE_HOST}"
     #   xml.tag! "maturity", ""
     #   xml.tag! "platform", ""
     #   xml.tag! "language", ""

        #Needs to be enumerated type - not free text
        #xml.tag! "license", g_service.list_of("license").first

        #xml.tag! "cost", g_service.list_of("cost").first.capitalize

        xml.tag! "docs" do
          if service.documentation_url
            xml.tag! "docsHome", service.documentation_url
          else
            xml.tag! "docsHome", service_url(service)
          end
        end

        # publications have to fit this regexp - can't be free text.
        # (PMC)[1-9][0-9]{0,8}|[1-9][0-9]{0,8}|(doi:)?[0-9]{2}\.[0-9]{4}/.*'
=begin
        publications = g_service.list_of("publication")
        if publications.empty?
          #xml.tag! "publications" do
          #  xml.tag! "publicationPrimaryID", ""
          #  xml.tag! "publicationOtherID", ""
          #end
        else
          publications.each do |pub|
            xml.tag! "publications" do
              xml.tag! "publicationsPrimaryID", pub
           #   xml.tag! "publicationOtherID", ""
            end
          end
        end
=end

  #      xml.tag! "credits" do
  #        xml.tag! "developer", ""
  #      end
      end
    end
  end
end