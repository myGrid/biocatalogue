#!/usr/bin/env ruby

# This script generates a report (in the log folder) on the coverage/levels of
# of service annotation.
#
# Usage: service_annotation_report [options]
#
#    -e, --environment=name           Specifies the environment to run this script under (test|development|production).
#                                     Default: production
#
#    -h, --help                       Show this help message.
#
# Depedencies:
# - All dependencies for the BioCatalogue application
# - Haml
# - Hashie

require 'rubygems'
require 'optparse'
require 'benchmark'
require 'ostruct'
require 'hashie'

require File.join(File.dirname(__FILE__), "shared", "counter")

class ServiceAnnotationReporter
  
  attr_accessor :options, :stats, :errors
  
  def initialize(args)
    @options = {
      :environment => (ENV['RAILS_ENV'] || "production").dup,
    }
    
    args.options do |opts|
      opts.on("-e", "--environment=name", String,
              "Specifies the environment to run this script under (test|development|production).",
              "Default: production") { |v| @options[:environment] = v }
    
      opts.separator ""
    
      opts.on("-h", "--help", "Show this help message.") { puts opts; exit }
      
      opts.parse!
    end
    
    @resource_types = [ OpenStruct.new({ :key => :services, :name => "All Services" }), 
                        OpenStruct.new({ :key => :soap_services, :name => "SOAP Services" }), 
                        OpenStruct.new({ :key => :rest_services, :name => "REST Services" }),
                        OpenStruct.new({ :key => :soap_operations, :name => "SOAP Operations" }),
                        OpenStruct.new({ :key => :soap_inputs, :name => "SOAP Inputs" }),
                        OpenStruct.new({ :key => :soap_output, :name => "SOAP Output" }),
                        OpenStruct.new({ :key => :rest_resources, :name => "REST Resources" }),
                        OpenStruct.new({ :key => :rest_methods, :name => "REST Methods" }),
                        OpenStruct.new({ :key => :rest_parameters, :name => "REST Parameters" }),
                        OpenStruct.new({ :key => :rest_representations, :name => "REST Representations" }) ]
    
    # @stats is a special kind of hash that allow Javascript like
    # property accessors on the keys.
    @stats = Hashie::Mash.new
    
    @errors = [ ]
    
    # Start the Rails app
    
    ENV["RAILS_ENV"] = @options[:environment]
    RAILS_ENV.replace(@options[:environment]) if defined?(RAILS_ENV)
    
    require File.join(File.dirname(__FILE__), '..', '..', 'config', 'environment')
    
    # Set up Haml
    gem 'haml'
    require 'haml'
    require 'haml/template'
    Haml::Template.options[:escape_html] = true
    @haml_engine = Haml::Engine.new(IO.read(File.join(File.dirname(__FILE__), "service_annotation_report", "template.haml")))
  end  
  
  def run
    current_time = Time.now.strftime('%Y%m%d-%H%M')
    
    calculate_stats
    
    puts "\n*****\nStoring report in: 'log/service_annotation_report_#{current_time}.html'\n*****\n"
    
    File.open(File.join(File.dirname(__FILE__), '..', '..', 'log', "service_annotation_report_#{current_time}.html"), "w") { |f| 
      f.write generate_html_content(current_time)
    }
  end
  
  # Calculates all the required stats for the report.
  #
  # Contains:
  #   - @stats.resources
  #     - @stats.resources.{resource_type}
  #       - @stats.resources.{resource_type}.id
  #       - @stats.resources.{resource_type}.name
  #       - @stats.resources.{resource_type}.url
  #       - @stats.resources.{resource_type}.has_description
  #       - @stats.resources.{resource_type}.has_tag
  #       - @stats.resources.services.service_type
  #       - @stats.resources.services.service_instance
  #       - @stats.resources.soap_services.has_documentation_url
  #       - @stats.resources.rest_services.has_documentation_url
  #       - @stats.resources.soap_services.operations
  #       - @stats.resources.rest_services.methods
  #   - @stats.summary
  #     - @stats.summary.resources
  #       - @stats.summary.resources.{resource_type}
  #         - @stats.summary.resources.{resource_type}.total
  #         - @stats.summary.resources.{resource_type}.has_descriptions
  #         - @stats.summary.resources.{resource_type}.has_tags
  #
  # NOTE: some statistics are not relevant for individual resource types since only certain annotations
  #       should be on certain resource types. See http://www.biocatalogue.org/wiki/doku.php?id=development:annotation.
  def calculate_stats
    @stats = Hashie::Mash.new
    
    @stats.resources = Hashie::Mash.new
    @stats.summary = Hashie::Mash.new
    @stats.summary.resources = Hashie::Mash.new
    
    # Initialise some of the collections
    @resource_types.each do |r|
      @stats.resources[r.key] = [ ]
      @stats.summary.resources[r.key] = [ ]
    end
    
    @stats.summary.resources.services = Service.count
    @stats.summary.resources.soap_services = SoapService.count
    @stats.summary.resources.soap_operations = SoapOperation.count
    @stats.summary.resources.soap_inputs = SoapInput.count
    @stats.summary.resources.soap_output = SoapOutput.count
    @stats.summary.resources.rest_services = RestService.count
    @stats.summary.resources.rest_resources = RestResource.count
    @stats.summary.resources.rest_methods = RestMethod.count
    @stats.summary.resources.rest_parameters = RestParameter.count
    @stats.summary.resources.rest_representations = RestRepresentation.count
    
    Service.all.each do |service|
      
      s = Hashie::Mash.new
      s.id = service.id
      s.name = BioCatalogue::Util.display_name(service)
      s.url = BioCatalogue::Api.uri_for_object(service)
      s.has_description = "N/A"
      s.has_tag = field_or_annotation_has_value?(service, :tag)
      
      service_instance = service.latest_version.service_versionified
      
      s.service_type = service_instance.service_type_name
      
      si = Hashie::Mash.new
      si.id = service_instance.id
      si.name = BioCatalogue::Util.display_name(service_instance)
      si.url = BioCatalogue::Api.uri_for_object(service_instance)
      si.has_tag = "N/A"
      
      case service_instance
        when SoapService
          si.has_description = (field_or_annotation_has_value?(service_instance, :description) || service_instance.description_from_soaplab.blank?)
          @stats.resources.soap_services << si
        when RestService
          si.has_description = field_or_annotation_has_value?(service_instance, :description)
          @stats.resources.rest_services << si
      end
      
      s.service_instance = si 
      
      @stats.resources.services << s
      
    end
  end
  
  def generate_html_content(timestamp)
    @haml_engine.render Object.new, :timestamp => timestamp, :resource_types => @resource_types, :stats => @stats, :errors => @errors
  end
  
  def field_or_annotation_has_value?(obj, field, annotation_attribute=field.to_s)
    if obj.respond_to? field
      return (!obj.send(field).blank? || !obj.annotations_with_attribute(annotation_attribute).blank?)  
    else
      return !obj.annotations_with_attribute(annotation_attribute).blank?
    end
  end
  
end

puts Benchmark.measure {
  ServiceAnnotationReporter.new(ARGV.clone).run
}
