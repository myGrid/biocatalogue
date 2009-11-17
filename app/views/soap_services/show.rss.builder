# BioCatalogue: app/views/soap_services/show.rss.builder
#
# Copyright (c) 2008, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

xml.instruct!

xml.rss "version" => "2.0" do
 xml.channel do
   xml.title("BioCatalogue Pilot, Soap Service")
   xml.link(formatted_soap_services_url(:rss))
   xml.description("Soap Service in BioCatalogue")
     xml.item do
       xml.title(display_name(@soap_service))
       xml.description(@soap_service.description)
       xml.link(formatted_soap_service_url(@soap_service, :html))
       xml.pubDate(@soap_service.created_at.to_s(:rfc822))
     end
 end
end