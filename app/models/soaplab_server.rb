# BioCatalogue: app/models/soaplab_server.rb
#
# Copyright (c) 2008, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

require 'open-uri'

class SoaplabServer < ActiveRecord::Base
  acts_as_trashable
  
  acts_as_annotatable
  
  validates_presence_of :name, :location
  #validates_uniqueness_of :location, :message => "already exists in BioCatalogue"
  validates_url_format_of :location,
                          :allow_nil => false
  #before_create :save_services
  #before_update :save_services
  #@service_urls = {}
  attr_accessor :wsdl_urls
  
  
  # save the soap services on this server in
  # the database
  def save_services(current_user)
    @error_urls        = []
    @existing_services = []
    @new_services      = []
    @wsdl_urls         = get_wsdl_from_server(self.location)
    
    unless @wsdl_urls.empty?  
      @wsdl_urls.each { |url|
         soap_service  = SoapService.new({:wsdl_location => url})
         success, data = soap_service.populate
      if success and SoapService.check_duplicate(url, data["endpoint"]) != nil
         @existing_services << soap_service.service(true)
         logger.info("This service exists in the database")
      else
        transaction do
          begin
            if success 
              c_success = soap_service.create_service(data["endpoint"], current_user, annotation=nil) 
              if c_success
                @new_services << soap_service.service(true)
                logger.info("INFO: registered service - #{url}. SUCCESS:")
              else
                @error_urls << url
                logger.error("ERROR: post_create failed for service - #{url}. ")
              end
            end
          rescue Exception => ex
            @error_urls << url
            logger.error("ERROR: failed to register service - #{url}. soaplab registration Exception:")
            logger.error(ex)
          end
        end
      end
      }
    end
    return [@new_services, @existing_services, @error_urls]
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
   
end
