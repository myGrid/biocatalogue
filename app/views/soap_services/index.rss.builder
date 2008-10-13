xml.instruct!

xml.rss "version" => "2.0" do
 xml.channel do
   xml.title("BioCatalogue Pilot, All Soap Services")
   xml.link(formatted_soap_services_url(:rss))
   xml.description("All BioCatalogue Soap Services ")
   @soap_services.each do |service|
     xml.item do
       xml.title(service.name)
       xml.description(service.description)
       xml.link(formatted_soap_service_url(service, :html))
       xml.pubDate(service.created_at.to_s(:rfc822))
     end
   end

 end
end