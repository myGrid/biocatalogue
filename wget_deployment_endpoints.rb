#!/usr/bin/env ruby

# This script attempts to access the endpoint of the service deployments and record the statuses
# in the online_statuses table. It also records references to the ServiceDeployment
# object whose endpoint was access
# For accessing the  endpoints, it uses the open-uri library
#
# This scripts records simple online/offline status. Only endpoints that generate the
# an HTTP 404 status code are considered to be offline. If the stutus cannot be determined
# because of some condition like a timeout, the status is set to unknown. A debug message is
# also added where possible.

# TODO:
# See what other error codes should be mapped to offline status

require 'benchmark'
require 'timeout'
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
    time = 0.0
    
    # attempt to read the endpoint and timeout after 20 seconds
    begin
      time = Benchmark.realtime(){
        Timeout::timeout(20) do
            ep = deployment.endpoint
            #open(deployment.endpoint,
            #       'User-Agent' => 'Ruby-Wget').read
            data = %x[curl -I #{ep}]
            puts "curl data"
            puts data
        end
      }
      status = 'Online'
      msg = "connected successfully"
      
    rescue Timeout::Error,Errno::ETIMEDOUT,Timeout::Error => timeout
      time = 20.0
      msg = "connection timed out"
      puts "timeout on accessing #{deployment.endpoint}"
    
    rescue Errno::ECONNREFUSED => conn_refused
      msg = "connection refused"
      puts "Connection refused #{deployment.endpoint}"
      
    rescue OpenURI::HTTPError => ex
      if ['404'].include?(ex.io.status[0]) 
        #status = 'Offline'
        #msg = "got an HTTP 404 status code "
        msg = "could not verify status. Got HTTP 404 status code"
        
      elsif ['411'].include?(ex.io.status[0])
        status = 'Online'
        msg = "service seems to be online but request was not correctly formed"
      else
        #status = 'Online'
        msg = "got an HTTP #{ex.io.status[0]} status code "
      end
      ex.io.meta.each{ |k, v| puts "#{k} => #{v}"}
      puts ex.io.base_uri
      
    rescue Exception => ex
     msg = "exception occured which connecting to server "
     puts ex
     
    end
      puts status
      puts time
      on_stat   = OnlineStatus.new(:status     => status, 
                                :pingable_id   =>  deployment.id,
                                :pingable_type => deployment.class.to_s,
                                :message        => msg, 
                                :connection_time => time)
      begin
        on_stat.save!
      rescue Exception => ex
        puts "Failed to record status of : #{deployment.id}. Error:"
        puts ex
      end
    end
end

