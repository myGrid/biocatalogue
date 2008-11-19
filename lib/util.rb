# BioCatalogue: app/lib/util.rb
#
# Copyright (c) 2008, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

#require 'geo_kit/geocoders'
require 'dnsruby'
require 'addressable/uri'
require 'timeout'

module BioCatalogue
  module Util
    #include GeoKit::Geocoders
    
    @@logger = RAILS_DEFAULT_LOGGER
    
    # Attempts to lookup the geographical location of the URL provided.
    # This uses the GeoKit plugin to do the geocoding.
    # Returns a Gecode::GeoLoc object if successful, otherwise returnes nil.
    def Util.url_location_lookup(url)
      return nil if url.blank?
      
      loc = Util.ip_geocode(Dnsruby::Resolv.getaddress(Addressable::URI.parse(url).host))
      return loc.success ? loc : nil 
    rescue
      @@logger.error("Method BioCatalogue::Util.url_location_lookup errored. Exception:")
      @@logger.error($!)
      return nil
    end
    
    # This method borrows code/principles from the GeoKit plugin.
    def Util.ip_geocode(ip)
      geoloc = GeoKit::GeoLoc.new
            
      return geoloc unless /^(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})?$/.match(ip)
      
      url = "http://api.hostip.info/get_html.php?ip=#{ip}&position=true"
      
      info = ''
      
      begin
        timeout(5) { info = open(url, :proxy => HTTP_PROXY).read }
      rescue TimeoutError
        @@logger.error("Method BioCatalogue::Util.ip_geocode - timeout occurred when attempting to get info from HostIp.")
        return geoloc
      rescue
        @@logger.error("Method BioCatalogue::Util.ip_geocode - failed on call to HostIp. Exception:")
        @@logger.error($!)
        return geoloc
      end
      
      # Process the info into the GeoKit GeoLoc object...
      unless info.blank?
        yaml = YAML.load(info)
        geoloc.provider = 'hostip'
        geoloc.city, geoloc.state = yaml['City'].split(', ')
        country, geoloc.country_code = yaml['Country'].split(' (')
        geoloc.lat = yaml['Latitude'] 
        geoloc.lng = yaml['Longitude']
        geoloc.country_code.chop!
        geoloc.success = true unless geoloc.country_code == "XX"
      end
      
      return geoloc
    end
    
    def Util.city_and_country_from_geoloc(geoloc)
      return [ ] unless geoloc.is_a?(GeoKit::GeoLoc)
      return [ ] if geoloc.nil? or !geoloc.success
      
      city = nil
      country = nil
      
      unless geoloc.city == "(Private Address)" or geoloc.city == "(Unknown City)"
        city = geoloc.city
      end
      
      country = CountryCodes.country(geoloc.country_code)
      
      return [ city, country ]
    end
    
    # Given a varied collection of ActiveRecord model items, 
    # this method attempts to select and return a list of items 
    # of the class 'model' (specified), based on relationships from 
    # each individual item. Note: 'model' must be a Class representing
    # the ActiveRecord model in question.
    #
    # E.g: if the model specified is Service and the items contains a 
    # ServiceVersion, then the .service association of that ServiceVersion 
    # will be added into the collection returned back.
    #
    # Currently only supports Service for the 'model' parameter, for
    # deep relationship finding. But other models can still be used,
    # they will just match themselves in items.
    def Util.discover_model_objects_from_collection(model, items)
      model_items = [ ]
      
      items.each do |r|
        if r.is_a?(ActiveRecord::Base)
          if r.is_a?(model)
            model_items << r
          else
            case model.to_s
              when "Service"
                puts "BioCatalogue::Util.discover_model_objects_from_collection - model=Service"
                case r
                  when ServiceVersion, ServiceDeployment, SoapService
                    model_items << r.service
                  when SoapOperation  
                    model_items << r.soap_service.service
                  when SoapInput, SoapOutput  
                    model_items << r.soap_operation.soap_service.service
                end
            end
          end
        end
      end
      
      return model_items.uniq
    end
  end
end