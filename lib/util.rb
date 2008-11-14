# BioCatalogue: app/lib/util.rb
#
# Copyright (c) 2008, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

require 'geo_kit/geocoders'
require 'dnsruby'
require 'addressable/uri'

module BioCatalogue
  module Util
    include GeoKit::Geocoders
    
    @@logger = RAILS_DEFAULT_LOGGER
    
    # Attempts to lookup the geographical location of the URL provided.
    # This uses the GeoKit plugin to do the geocoding.
    # Returns a Gecode::GeoLoc object if successful, otherwise returnes nil.
    def Util.url_location_lookup(url)
      return nil if url.nil?
      
      begin
        location = IpGeocoder.geocode(Dnsruby::Resolv.getaddress(Addressable::URI.parse(url).host))
        return (location.success ? (location.country_code == "XX" ? nil : location) : nil)
      rescue Exception => ex
        @@logger.info("Method BioCatalogue::Util.url_location_lookup errored. Exception:")
        @@logger.info(ex)
        return nil
      end
    end
    
  end
end