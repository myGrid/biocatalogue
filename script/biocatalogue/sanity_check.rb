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
    
    puts ""
    puts ""
  
    # Check that all Service objects have at least:
    #   - One valid ServiceDeployment, that has at least one valid ServiceVersion that points to a valid SoapService or RestService.
    #   - One valid ServiceVersion, that points to a valid SoapService or RestService and has at least one valid ServiceDeployment.
  
    Service.all.each do |service|
      puts "ERROR: Service #{service.id} has no ServiceDeployments" if service.service_deployments.count < 1
      service.service_deployments.each do |service_deployment|
        check_service_version(service_deployment.service_version, "ERROR: ServiceDeployment #{service_deployment.id} does not have a valid associated ServiceVersion")
      end
      
      puts "ERROR: Service #{service.id} has no ServiceVersions" if service.service_versions.count < 1
      service.service_versions.each do |service_version|
        check_service_version(service_version)
      end
    end
    
        
    # Check for orphaned ServiceVersion, ServiceDeployment and ServiceProviderHostname objects.
    
    ServiceVersion.all.each do |service_version|
      puts "ERROR: ServiceVersion #{service_version.id} does not have a valid associated Service" if service_version.service.blank?
    end
    
    ServiceDeployment.all.each do |service_deployment|
      puts "ERROR: ServiceDeployment #{service_deployment.id} does not have a valid associated Service" if service_deployment.service.blank?
    end
    
    ServiceProviderHostname.all.each do |service_provider_hostname|
      puts "ERROR: ServiceProviderHostname #{service_provider_hostname.id} does not have a valid associated ServiceProvider" if service_provider_hostname.service_provider.blank?
    end
    
    
    # Check that all ServiceProvider objects have at least one ServiceDeployment.
    
    ServiceProvider.all.each do |service_provider|
      puts "ERROR: ServiceProvider #{service_provider.id} does not have at least one associated ServiceDeployment" if service_provider.service_deployments.count < 1
    end

    
    # Check that all ServiceDeployment objects have a valid ServiceProvider.
    
    ServiceDeployment.all.each do |service_deployment|
      puts "ERROR: ServiceDeployment #{service_deployment.id} does not have a valid associated ServiceProvider" if service_deployment.provider.blank?
    end
    
    
    # Check that ServiceProviders have at least one ServiceProviderHostname.
    
    ServiceProvider.all.each do |service_provider|
      puts "ERROR: ServiceProvider #{service_provider.id} does not have at least one associated ServiceProviderHostname" if service_provider.service_provider_hostnames.count < 1
    end
    
    
    # Check for "orphaned" SoapService or RestService objects.
    
    SoapService.all.each do |soap_service|
      puts "ERROR: SoapService #{soap_service.id} does not have a valid associated ServiceVersion" if soap_service.service_version.blank?
    end
    
    RestService.all.each do |rest_service|
      puts "ERROR: RestService #{rest_service.id} does not have a valid associated ServiceVersion" if rest_service.service_version.blank?
    end
    
    
    # Check for "orphaned" SoapOperations, SoapInputs and SoapOutputs.
    
    SoapOperation.all.each do |soap_operation|
      puts "ERROR: SoapOperation #{soap_operation.id} does not have a valid associated SoapService" if soap_operation.soap_service.blank?
    end
    
    SoapInput.all.each do |soap_input|
      puts "ERROR: SoapInput #{soap_input.id} does not have a valid associated SoapOperation" if soap_input.soap_operation.blank?
    end
    
    SoapOutput.all.each do |soap_output|
      puts "ERROR: SoapOutput #{soap_output.id} does not have a valid associated SoapOperation" if soap_output.soap_operation.blank?
    end


    # Check for "orphaned" RestResources, RestMethods, RestParameters, RestRepresentations, RestMethodParameters, and RestMethodRepresentations objects.
    
    RestResource.all.each do |rest_resource|
      puts "ERROR: RestResource #{rest_resource.id} does not have a valid associated RestService" if rest_resource.rest_service.blank?
    end

    RestMethod.all.each do |rest_method|
      puts "ERROR: RestMethod #{rest_method.id} does not have a valid associated RestResource" if rest_method.rest_resource.blank?
    end
    
    RestParameter.all.each do |rest_parameter|
      puts "ERROR: RestParameter #{rest_parameter.id} does not have a valid associated RestMethodParameter" if rest_parameter.rest_method_parameters.blank?
    end
    
    RestRepresentation.all.each do |rest_representation|
      puts "ERROR: RestRepresentation #{rest_representation.id} does not have a valid associated RestMethodRepresentation" if rest_representation.rest_method_representations.blank?
    end    
    
    RestMethodParameter.all.each do |rest_method_parameter|
      puts "ERROR: RestMethodParameter #{rest_method_parameter.id} does not have a valid associated RestMethod" if rest_method_parameter.rest_method.blank?
      puts "ERROR: RestMethodParameter #{rest_method_parameter.id} does not have a valid associated RestParameter" if rest_method_parameter.rest_parameter.blank?
    end
    
    RestMethodRepresentation.all.each do |rest_method_representation|
      puts "ERROR: RestMethodRepresentation #{rest_method_representation.id} does not have a valid associated RestMethod" if rest_method_representation.rest_method.blank?
      puts "ERROR: RestMethodRepresentation #{rest_method_representation.id} does not have a valid associated RestRepresentation" if rest_method_representation.rest_representation.blank?
    end

        
    # Check for providers with no associated Services
    
    ServiceProvider.all.each do |provider|
      puts "ERROR: ServiceProvider #{provider.id} has no associated services. " if provider.services.count == 0
    end
    
    
    # Check for orphaned Annotations
    
    Annotation.all.each do |annotation|
      puts "ERROR: Annotation #{annotation.id} does not have a valid associated Source" if annotation.source.nil?
      puts "ERROR: Annotation #{annotation.id} does not have a valid associated Annotatable" if annotation.annotatable.nil?
      puts "ERROR: Annotation #{annotation.id} does not have a valid associated Attribute" if annotation.attribute.nil?
      puts "ERROR: Annotation #{annotation.id} has an empty value" if annotation.value.blank?
    end
    
    
    # Check for orphaned ServiceTests
    
    ServiceTest.all.each do |service_test|
      puts "ERROR: ServiceTest #{service_test.id} does not have a valid associated Service" if service_test.service.nil?
    end

    
    # TODO: check Annotation versions
    # TODO: check for duplicate ServiceTests
    # TODO: check for orphaned/duplicate UrlMonitors
    # TODO: check for orphaned ContentBlobs
  
  end
  
  def check_service_version(service_version, message_if_blank="ERROR: ServiceVersion is blank")
    if service_version.blank?
      puts message_if_blank
    else
      if service_version.service_versionified.blank?
        puts "ERROR: ServiceVersion #{service_version.id} does not have a valid service version instance (aka service_versionified)"
      elsif not %w( SoapService RestService ).include? service_version.service_versionified_type
        puts "ERROR: ServiceVersion #{service_deployment.service_version.id} has a service_versionified that is not a SoapService or RestService. It is: '{service_version.service_versionified_type}'"
      end
    end
  end
  
end

puts Benchmark.measure {
  SanityCheck.new(ARGV.clone).run
}
