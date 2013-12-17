#!/usr/bin/env ruby


# This script registers url and that need to be monitored 
# Example: 
#
#
#
# Usage: update_url_monitors [options]
#
#    -e, --environment=name           Specifies the environment to run this import script under (test|development|production).
#                                     Default: development
#
#    -h, --help                       Show this help message.
#
#    -t, --test                       Run the script in test mode (so won't actually store anything in the db, only a listing of url to monitor will be made).
#
# 

require 'benchmark'
require 'optparse'

class MonitorUpdate
  
  attr_accessor :options
  
  def initialize(args)
    @options = {
      :environment => (ENV['RAILS_ENV'] || "development").dup,
    }
    
    args.options do |opts|

      opts.on("-e", "--environment=name", String,
              "Specifies the environment to run this update script under (test|development|production).",
              "Default: development") { |v| @options[:environment] = v }
    
      opts.separator ""
    
      opts.on("-h", "--help", "Show this help message.") { puts opts; exit }
      
      opts.on("-t", "--test", "Run the script in test mode (so won't actually store anything in the db and will only show the url to be added for monitoring).") { @options[:test] = true }
    
      opts.parse!
    end
    
    
    # Start the Rails app
      
    ENV["RAILS_ENV"] = @options[:environment]
    RAILS_ENV.replace(@options[:environment]) if defined?(RAILS_ENV)
    
    require File.dirname(__FILE__) + '/config/environment'
    
  end

  def run
    
     if @options[:test]
      puts ""
      puts "**************************************************************"
      puts "NOTE: Running in test mode. No saves will be made to the DB"
      puts "*************************************************************"
     end

      Service.all.each do |service|
      # get all service deploments
      deployments = service.service_deployments
    
      #register the endpoints for monitoring
      update_deployment_monitors(deployments)
    
      #get all service instances(soap & rest)
      instances = service.service_version_instances
    
    
      soap_services = instances.delete_if{ |instance| instance.class.to_s != "SoapService" }
      update_soap_service_monitors(soap_services)
    
      end
  end
  
  
protected 

# from a list service deployments, check if
# the endpoints are being monitored already.
# If not, add the endpoint to the list of endpoints to
# to monitor

def update_deployment_monitors(deployments)
  
  deployments.each do |dep|
    monitor = UrlMonitor.first(:conditions => ["parent_id= ? AND parent_type= ?", dep.id, dep.class.to_s ])
    if monitor.nil?
      mon = UrlMonitor.new(:parent_id => dep.id, 
                              :parent_type => dep.class.to_s, 
                              :property => "endpoint")
      if !@options[:test]
        if mon.save
          puts "Created new monitor for deployment id : #{dep.id}"
        end
      else
          puts "found endpoint that needs monitoring : #{dep.endpoint}"
      end
  end
  end
end

# from a list of endpoints soap services
# add the wsdl locations to the list of url to monitor
# if these are not being monitored already

def update_soap_service_monitors(soap_services)
  
  soap_services.each do |ss|
    monitor = UrlMonitor.first(:conditions => ["parent_id= ? AND parent_type= ?", ss.id, ss.class.to_s ])
    if monitor.nil?
      mon = UrlMonitor.new(:parent_id => ss.id, 
                              :parent_type => ss.class.to_s, 
                              :property => "wsdl_location")
      if !@options[:test]
        if mon.save
          puts "Created new monitor for soap service id : #{ss.id}"
        end
      else
          puts "found wsdl that needs monitoring : #{ss.wsdl_location}"
      end
    end
  end
  
end


end

# Redirect $stdout to log file
puts "Redirecting output of $stdout to log file: update_url_monitors.log ..."
$stdout = File.new("update_url_monitors.log", "w")
$stdout.sync = true

puts Benchmark.measure { MonitorUpdate.new(ARGV.clone).run }

# Reset $stdout
$stdout = STDOUT

