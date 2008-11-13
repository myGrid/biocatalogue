# BioCatalogue: app/models/soaplab_server.rb
#
# Copyright (c) 2008, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

require 'open-uri'

class SoaplabServer < ActiveRecord::Base
  acts_as_trashable
  validates_presence_of :name, :location
  validates_uniqueness_of :location, :message => "already exists in BioCatalogue"
  validates_url_format_of :location,
                          :allow_nil => false
  #before_create :save_services
  before_update :save_services
  #@service_urls = {}
  attr_accessor :wsdl_urls
  
  @wsdl_urls = []
   
  def save_services(current_user)
    
    @wsdl_urls = get_wsdl_from_server(self.location)
    
    unless @wsdl_urls.empty?  
      new_wsdls = new_existing_urls(@wsdl_urls)['new'] 
      
      new_wsdls.each { |url|
      transaction do
        soap_service = SoapService.new
        soap_service.wsdl_location = url
        success, data = soap_service.populate
        soap_service.save!
        if soap_service.save
          soap_service.post_create(soap_service, data["endpoint"], current_user)
        end
     
        end
      }
     end
  end
    
  # hack to get the wsdl documents from
  # a soaplab server
  def get_wsdl_from_server(server_url)
    begin
      wsdls = []  
      open(server_url.strip()).each { |line|
        wsdls << line.split('"')[1] if line =~ /http:/ or line =~ /https:/}
      wsdls 
    rescue
      errors.add_to_base("there were problems accessing the soaplab server")
      wsdls
    end
  end
  
  def new_existing_urls(urls=[])
    urls = urls || get_wsdl_from_server(self.location)
    all_urls     = []
    @service_urls = {}
    
    SoapService.find(:all).each{ |s| all_urls << s.wsdl_location }
    new = urls - all_urls
    @service_urls['new']      = new
    @service_urls['existing'] = urls - new
    
    @service_urls
  end
  
end
