require 'open-uri'

class SoaplabServer < ActiveRecord::Base
  acts_as_trashable
  
  before_create :save_services
   
  def save_services
    
    @wsdl_urls = get_wsdl_from_server(self.location)
    @test_wsdls = @wsdl_urls.first(10)
    @test_wsdls.each { |url|
    
    transaction do
      @soap_service = SoapService.new
      @soap_service.wsdl_location = url
      @soap_service.description = url
      @soap_service.save(false)
    end
    } 
  end
    
  # hack to get the wsdl documents from
  # a soaplab server
  def get_wsdl_from_server(server_url)
    wsdls = []  
    open(server_url.strip()).each { |line|
      wsdls << line.split('"')[1] if line =~ /http:/}
  
    wsdls 
  end
 
end
