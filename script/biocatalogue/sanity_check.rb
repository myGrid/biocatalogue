#!/usr/bin/env ruby

# This script does a sanity check over the whole database to check:
# - data integrity and consistency
#
#
# Usage: sanity_check [options]
#
#    -e, --environment=name           Specifies the environment to run this script under (test|development|production).
#                                     Default: development
#
#    -h, --help                       Show this help message.
#
# Depedencies:
# - Rails (v2.3.2)

require 'optparse'
require 'benchmark'




class SanityCheck
  
  attr_accessor :options, :biocat_agent, :rules
  
  def initialize(args)
    @options = {
      :environment => (ENV['RAILS_ENV'] || "development").dup,
    }
    
    args.options do |opts|
      opts.on("-e", "--environment=name", String,
              "Specifies the environment to run this script under (test|development|production).",
              "Default: development") { |v| @options[:environment] = v }
    
      opts.separator ""
    
      opts.on("-h", "--help", "Show this help message.") { puts opts; exit }
      
      opts.parse!
    end
  
    # Start the Rails app
    
    ENV["RAILS_ENV"] = @options[:environment]
    RAILS_ENV.replace(@options[:environment]) if defined?(RAILS_ENV)
    
    require File.join(File.dirname(__FILE__), '..', '..', 'config', 'environment')
  end  
  
  def run
  
    # 1. Check that all Service objects have at least:
    #    - One valid ServiceDeployment, that has at least one valid ServiceVersion that points to a valid SoapService or RestService.
    #    - One valid ServiceVersion, that points to a valid SoapService or RestService and has at least one valid ServiceDeployment.
  
    Service.all.each do |service|
      puts "ERROR: Service #{service.id} has no ServiceDeployments" if service.service_deployments.count < 1
      service.service_deployments.each do |service_deployment|
        check_service_version(service_deployment.service_version, "ERROR: ServiceDeployment #{service_deployment.id} does not have an associated ServiceVersion")
      end
      
      puts "ERROR: Service #{service.id} has no ServiceVersions" if service.service_versions.count < 1
      service.service_versions.each do |service_version|
        check_service_version(service_version)
      end
    end
    
    # 2. Check for "orphaned" SoapService or RestService objects.
    
    SoapService.all.each do |soap_service|
      puts "ERROR: SoapService #{soap_service.id} does not have an associated ServiceVersion" if soap_service.service_version.blank?
    end
    
    RestService.all.each do |rest_service|
      puts "ERROR: RestService #{rest_service.id} does not have an associated ServiceVersion" if rest_service.service_version.blank?
    end
    
    # 3. Check for providers with no associated Services
    
    ServiceProvider.all do |provider|
      puts "ERROR: ServiceProvidr #{provider.id} has no associated services. " if provider.services.count == 0
    end
    
    # TODO: check for orphaned Annotations
    # TODO: check for orphaned/duplicate ServiceTests and UrlMonitors
    # TODO: check for orphaned ContentBlobs
  
  end
  
  def check_service_version(service_version, message_if_blank="ERROR: ServiceVersion is blank")
    if service_version.blank?
      puts message_if_blank
    else
      if service_version.service_versionified.blank?
        puts "ERROR: ServiceVersion #{service_version.id} does not have a service version instance (aka service_versionified)"
      elsif not %w( SoapService RestService ).include? service_version.service_versionified_type
        puts "ERROR: ServiceVersion #{service_deployment.service_version.id} has a service_versionified that is not a SoapService or RestService. It is: '{service_version.service_versionified_type}'"
      end
    end
  end
  
end

puts Benchmark.measure {
  SanityCheck.new(ARGV.clone).run
}
