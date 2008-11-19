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

if ENABLE_SEARCH
  Service.rebuild_solr_index
  ServiceVersion.rebuild_solr_index
  ServiceDeployment.rebuild_solr_index
  SoapService.rebuild_solr_index
  SoapOperation.rebuild_solr_index
  SoapInput.rebuild_solr_index
  SoapOutput.rebuild_solr_index
  User.rebuild_solr_index
  ServiceProvider.rebuild_solr_index
end
