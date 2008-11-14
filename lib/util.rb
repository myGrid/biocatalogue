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
        geoloc.success = true unless geoloc.city == "(Private Address)" or geoloc.country_code == "XX"
      end
      
      return geoloc
    end
  end
end