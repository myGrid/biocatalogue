#!/usr/bin/env ruby

# This script pings the endpoint of the service deployments and record the statuses
# in the online_statuses table. It also records references to the ServiceDeployment
# object whose endpoint was pinged
# For pinging the endpoints, it uses the onlooker plugin
#
require 'open-uri'

env = "development"

unless ARGV[0].nil? or ARGV[0] == ''
  env = ARGV[0]
end

RAILS_ENV = env

# Load up the Rails app
require File.dirname(__FILE__) + '/config/environment'

Service.find(:all).each do |service|
    service.service_deployments.each do |deployment| 
    status = 'Unknown' 
    begin
      open(deployment.endpoint,
           'User-Agent' => 'Ruby-Wget').read
      status = 'Online'
    rescue Exception=> ex
      if ex.io.status == 404
        status = 'Offline'
      else
        status = 'Online'
      end
      ex.io.meta.each{ |k, v| puts "#{k} => #{v}"}
      puts ex.io.base_uri
    end
      puts status
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

