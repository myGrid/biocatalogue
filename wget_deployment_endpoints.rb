#!/usr/bin/env ruby

# This script attempts to access the endpoint of the service deployments and record the statuses
# in the online_statuses table. It also records references to the ServiceDeployment
# object whose endpoint was access
# For accessing the  endpoints, it uses the open-uri library
#
# This scripts records simple online/offline status. Only endpoints that generate the
# 'not found' exception are considered to be offline

# TODO:
# See what other error codes should be mapped to offline status


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
    msg = ''
    
    begin
      res = open(deployment.endpoint,
              'User-Agent' => 'Ruby-Wget').read
      status = 'Online'
      msg = "connected successfully"
      
    rescue Timeout::Error => timeout
      msg = "connection timed out"
      puts "timeout on accessing #{deployment.endpoint}"
    
    rescue Errno::ECONNREFUSED => conn_refused
      msg = "connection refused"
      puts "Connection refused #{deployment.endpoint}"
      
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
                                :pingable_type => deployment.class.to_s,
                                :message => msg)
      begin
        on_stat.save!
      rescue Exception => ex
        puts "Failed to record status of : #{deployment.id}. Error:"
        puts ex
      end
    end
end

