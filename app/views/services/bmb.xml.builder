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

#@services = @services[1..100]

# Hand picked services that meet the criteria.
# Use 'service annotation levels' to find best services:
# https://www.biocatalogue.org/curation/reports/annotation_level?action=annotation_level&controller=curation&sort_by=ann_level&sort_order=desc

service_ids = [2071, 2088, 2697, 3099, 3354, 2052, 3340, 3352, 2711, 2752, 2060, 3418, 3420,
               2653, 2700, 2, 30, 31] #3718 (too new?)
#rejects: [3329, 3104, 2715, 2615, 2616, 1924, 2698, 2146]
#
services = []
service_ids.each { |s_id| services << Service.find(s_id).service_version_instances }
services.flatten!

# Debugging & statsistics
count_for = {}
count_for['rest_services'] = 0
count_for['soap_services'] = 0
count_for['excluded'] = 0
debug_mode = false


xml.tag! "resources", :"xmlns" => "http://biotoolsregistry.org",
         :"xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance",
         :"xsi:schemaLocation" => "http://biotoolsregistry.org biotools-beta08.xsd" do

  #set services to @services for full list
  services.each_with_index do |service, index|

    # Generic service is meant by g_service. A service is either of the RestService class or the SoapService class.
    # g_service is the generic Service class common to both
    g_service = service.service
    categories = g_service.annotations.select { |ann| ann.value_type == "Category" }.collect { |cat| cat.value.name }

    # Map the Services Categories to EDAM Topics and EDAM Operations
    edam_topics = []
    categories.each { |x| edam_topics << map_categories_to_edam_topics(x) }
    edam_topics.uniq!
    operations = []
    categories.each { |x| operations << map_categories_to_edam_operations(x) }
    operations.reject! { |c| c.empty? }
    operations.uniq!

    # For the homepage we'll be using the documentation URL
    doc_link = service.preferred_documentation_url if service.has_documentation_url?
    homepage = URI::extract(doc_link).first

   # Contact is a free text annotation and we need to extract JUST an email address or URL from it.
   # This takes the first. Splits by whitespace. Check each item for valid address.
   # Could make it loop over all contact annotations if the first one has neither email or url
    contact = g_service.list_of("contact").first
    unless contact.nil?
      contacts = contact.split(" ")
      contacts.select! { |element| ValidatesEmailFormatOf::validate_email_format(element) == nil}
      if !contacts.empty?
        contact_email = contacts.first
      elsif contact =~ URI::regexp
        contact_url = URI::extract(contact).last
      end
    end

=begin
    TODO: Filter services by description! The requirements are that:
    Description should be a concise human-readable scientific description of the service.
    It should not contain URLs, e.g.
    <description>"GorI @ IBCP (http://gbio-pbil.ibcp.fr)"</description>
    Or be a miniature essay (see e.g. "WSEasyGene_1_2a_ws0") for which a good description would be:
    "The EasyGene 1.0 server produces a list of predicted genes given a sequence of prokaryotic NA. Each prediction is attributed with a significance score (R-value) indicating how likely it is to be just a non-coding open reading frame rather than a real gene."
    Or be truncated text (see e.g. "OligoSelection")
    Or give technical usage information (see e.g. "Search")
    Or merely restate the title (see e.g. "SMART" for which the description is "SMART webservice"
=end



    valid = !operations.empty? &&
        !edam_topics.empty? &&
        !g_service.preferred_description.nil? &&
        !g_service.archived? &&
        !(contact_url.nil? && contact_email.nil?) &&
        !homepage.nil?


    if valid
      if !debug_mode
        #xml.tag! "resource", :toolid => "#{1000 + index}" do
        xml.tag! "resource" do
          xml.tag! "name", "#{service.name}"
          xml.tag! "homepage", homepage
          #xml.tag! "version", g_service.latest_version.version
          #xml.tag! "collectionName", "#{SITE_BASE_HOST}"
          #xml.tag! "uses", ""
          #xml.tag! "softwareType", "Web Service", :uri => 'http://www.ebi.ac.uk/swo/interface/SWO_9000051'
          xml.tag! "resourceType", "Tool (analysis)" #, :uri => 'http://www.ebi.ac.uk/swo/interface/SWO_9000051'
          xml.tag! "interface" do
            if service.is_a?(RestService)
              xml.tag! "interfaceType", "REST API", :uri => 'http://www.ebi.ac.uk/swo/interface/SWO_50000005'
              # xml.tag! "interfaceDocs", "http://www.restdoc.org/spec.html"
              # xml.tag! "interfaceSpecURL", ""
              # xml.tag! "specificationFormat", ""
              count_for['rest_services'] += 1
            else
              xml.tag! "interfaceType", "SOAP WS", :uri => 'http://www.ebi.ac.uk/swo/interface/SWO_5000004'
              # xml.tag! "interfaceDocs", "http://www.w3.org/TR/soap/"
              # xml.tag! "interfaceSpecURL", ""
              # xml.tag! "specificationFormat", ""
              count_for['soap_services'] += 1
            end
          end
          #xml.tag! "description", g_service.preferred_description
          xml.tag! "description", g_service.preferred_description ? truncate(service.preferred_description, length: 1000) : ""

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
          xml.tag! "contactDetails" do
=begin
          if (submitter = g_service.submitter).class == Registry
            xml.tag! "contactURL", submitter.homepage
            xml.tag! "contactName", submitter.display_name
     #       xml.tag! "tel", ""
     #       xml.tag! "role", ""
          else #else individual
            xml.tag! "contactEmail", submitter.email
            xml.tag! "contactName", submitter.display_name
     #       xml.tag! "tel", ""
     #       xml.tag! "role", ""
          end
=end
            if !contact_url.nil?
              xml.tag! "contactURL", contact_url
            else
              xml.tag! "contactEmail", contact_email
            end
          end

          xml.tag! "sourceRegistry", "#{service_url(service)}"
          #   xml.tag! "maturity", ""
          #   xml.tag! "platform", ""
          #   xml.tag! "language", ""

          #Needs to be enumerated type - not free text
          #xml.tag! "license", g_service.list_of("license").first

          #xml.tag! "cost", g_service.list_of("cost").first.capitalize

          xml.tag! "docs" do
              xml.tag! "docsHome", homepage
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
    else
      if debug_mode
        count_for['excluded'] += 1
        xml.tag! 'DEBUG' do
          xml.tag! 'instanceofservice', service.inspect
          xml.tag! 'service', g_service.inspect
          xml.tag! 'ops', operations
          xml.tag! 'tops', edam_topics
          xml.tag! 'desc', g_service.preferred_description
          xml.tag! 'arch', g_service.archived?
          xml.tag! 'con-url', contact_url
          xml.tag! 'con-email', contact_email
          xml.tag! 'doc_page', service.service.list_of("documentation_url")
          xml.tag! 'homepage', homepage
        end
      end
    end
  end
  if debug_mode
    xml.tag! "rest", "Eligible REST Services = #{count_for['rest_services']}"
    xml.tag! "soap", "Eligible SOAP Services = #{count_for['soap_services']}"
    xml.tag! "exc", "Services Excluded = #{count_for['excluded']} / #{services.count}"
  end
end
