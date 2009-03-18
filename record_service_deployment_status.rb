#!/usr/bin/env ruby

# This script ensures that entries for the initial versions of annotation objects
# are in the annotation_versions table (as required by the annotations versioning mechanism).
#
# Note: only creates annotation_version entries for those annotation objects are on version 1.

env = "development"

unless ARGV[0].nil? or ARGV[0] == ''
  env = ARGV[0]
end

RAILS_ENV = env

# Load up the Rails app
require File.dirname(__FILE__) + '/config/environment'

require 'onlooker_helper'

Service.find(:all).each do |service|
    service.service_deployments.each do |deployment| 
      host      = BioCatalogue::OnLookerHelper.get_host(deployment.endpoint)
      host_type = BioCatalogue::OnLookerHelper.get_host_type(host)
      status    = OnLooker.check(host , host_type)
      on_stat   = OnlineStatus.new(:status => status, 
                                :pingable_id =>  deployment.id,
                                :pingable_type => deployment.class.to_s)
      begin
        on_stat.save!
      rescue Exception => ex
        puts "Failed to record status of : #{deployment.id}. Error:"
        puts ex
      end
    end
end

