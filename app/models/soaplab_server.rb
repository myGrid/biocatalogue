class SoaplabServer < ActiveRecord::Base
  
  #has_many :soap_services, :dependent => :destroy
   
  def save_services
    
    @wsdl_urls = get_wsdl_from_server(self.location)
    @test_wsdls = @wsdl_urls.first(2)
    @test_wsdls.each { |url|
    
    puts url 
    
    @web_service  = WebService.new
    @web_service.service_type = 'SOAP'
    @web_service.save
    @soap_service = @web_service.soap_services.build
    @soap_service.name = 'soaplab_service'
    @soap_service.wsdl_location = url
    @soap_service.description = url
    @soap_service.new_service_attributes = @soap_service.get_service_attributes(url)
    @soap_service.save
    } 
  end
    
  # hack to get the wsdl documents from
  # a soaplab server
  def get_wsdl_from_server(server_url)
    wsdls = []  
    open(server_url).each { |line|
      wsdls << line.split('"')[1] if line =~ /http:/}
  
    wsdls 
  end
end
