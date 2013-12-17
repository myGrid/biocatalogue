#!/usr/bin/env ruby

# This script sets the city and country fields of all 
# ServiceDeployment objects, using the geolocation
# functionality. 
#
# Note: only sets the city and country if location is blank.

env = "development"

unless ARGV[0].nil? or ARGV[0] == ''
  env = ARGV[0]
end

RAILS_ENV = env

# Load up the Rails app
require File.dirname(__FILE__) + '/config/environment'

ServiceDeployment.all.each do |sd|
  if sd.location.blank?
    puts "ServiceDeployment id #{sd.id} does not have city and country set. Attempting geolocation..."
    geoloc = BioCatalogue::Util.url_location_lookup(sd.endpoint)
    sd.city, sd.country = BioCatalogue::Util.city_and_country_from_geoloc(geoloc)
    sd.save
    puts "  New values saved! - City: #{sd.city}; Country: #{sd.country}"
    puts ""
  end
end
