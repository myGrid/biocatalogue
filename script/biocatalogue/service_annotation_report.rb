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

NOT_APPLICABLE = "N/A".freeze

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
                        OpenStruct.new({ :key => :soap_outputs, :name => "SOAP Outputs" }),
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
  #       - @stats.resources.{resource_type}.has_example
  #       - @stats.resources.services.service_type
  #       - @stats.resources.services.service_instance
  #       - @stats.resources.soap_services.has_documentation_url
  #       - @stats.resources.rest_services.has_documentation_url
  #       - @stats.resources.soap_services.operations
  #       - @stats.resources.rest_services.methods
  #       - @stats.resources.soap_operations.inputs
  #       - @stats.resources.soap_operations.outputs
  #       - @stats.resources.rest_methods.input_parameters
  #       - @stats.resources.rest_methods.input_representations
  #       - @stats.resources.rest_methods.output_parameters
  #       - @stats.resources.rest_methods.output_representations
  #   - @stats.summary
  #     - @stats.summary.resources
  #       - @stats.summary.resources.{resource_type}
  #         - @stats.summary.resources.{resource_type}.total
  #         - @stats.summary.resources.{resource_type}.has_descriptions
  #         - @stats.summary.resources.{resource_type}.has_tags
  #         - @stats.summary.resources.{resource_type}.has_examples
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
      @stats.summary.resources[r.key] = Hashie::Mash.new
    end
    
    # Build the information about the resources
    
    Service.all.each do |service|
      s = Hashie::Mash.new
      s.id = service.id
      s.name = BioCatalogue::Util.display_name(service)
      s.url = BioCatalogue::Api.uri_for_object(service)
      s.has_description = NOT_APPLICABLE
      s.has_tag = BioCatalogue::Util.field_or_annotation_has_value?(service, :tag)
      s.has_example = NOT_APPLICABLE
      
      service_instance = service.latest_version.service_versionified
      
      s.service_type = service_instance.service_type_name
      
      si = Hashie::Mash.new
      si.id = service_instance.id
      si.name = BioCatalogue::Util.display_name(service_instance)
      si.url = BioCatalogue::Api.uri_for_object(service_instance)
      si.has_tag = NOT_APPLICABLE
      si.has_example = NOT_APPLICABLE
      si.has_documentation_url = BioCatalogue::Util.field_or_annotation_has_value?(service_instance, :documentation_url)
      
      case service_instance
        when SoapService
          si.merge!(more_stats_hash_for_soap_service(service_instance))
          @stats.resources.soap_services << si
        when RestService
          si.merge!(more_stats_hash_for_rest_service(service_instance))
          @stats.resources.rest_services << si
      end
      
      s.service_instance = si
      
      @stats.resources.services << s
    end
    
    # Now generate the summary stats
    
    @stats.summary.resources.services.total = Service.count
    @stats.summary.resources.soap_services.total = SoapService.count
    @stats.summary.resources.soap_operations.total = SoapOperation.count
    @stats.summary.resources.soap_inputs.total = SoapInput.count
    @stats.summary.resources.soap_outputs.total = SoapOutput.count
    @stats.summary.resources.rest_services.total = RestService.count
    @stats.summary.resources.rest_resources.total = RestResource.count
    @stats.summary.resources.rest_methods.total = RestMethod.count
    @stats.summary.resources.rest_parameters.total = RestParameter.count
    @stats.summary.resources.rest_representations.total = RestRepresentation.count
    
    @resource_types.each do |r|
      @stats.summary.resources[r.key].has_descriptions = calculate_summary_total_for(r.key, :has_description)
      @stats.summary.resources[r.key].has_tags = calculate_summary_total_for(r.key, :has_tag)
      @stats.summary.resources[r.key].has_examples = calculate_summary_total_for(r.key, :has_example)
    end
  end
  
  def generate_html_content(timestamp)
    @haml_engine.render Object.new, :timestamp => timestamp, :resource_types => @resource_types, :stats => @stats, :errors => @errors
  end
  
  def more_stats_hash_for_soap_service(soap_service)
    h = Hashie::Mash.new
    
    h.has_description = (BioCatalogue::Util.field_or_annotation_has_value?(soap_service, :description) || soap_service.description_from_soaplab.blank?)
    
    h.operations = [ ]
    
    soap_service.soap_operations.each do |soap_operation|
      sop = Hashie::Mash.new
      sop.id = soap_operation.id
      sop.name = BioCatalogue::Util.display_name(soap_operation)
      sop.url = BioCatalogue::Api.uri_for_object(soap_operation)
      sop.has_description = BioCatalogue::Util.field_or_annotation_has_value?(soap_operation, :description)
      sop.has_tag = BioCatalogue::Util.field_or_annotation_has_value?(soap_operation, :tag)
      sop.has_example = NOT_APPLICABLE
      
      sop.inputs = [ ]
      sop.outputs = [ ]
      
      soap_operation.soap_inputs.each do |soap_input|
        sin = Hashie::Mash.new
        sin.id = soap_input.id
        sin.name = BioCatalogue::Util.display_name(soap_input)
        sin.url = BioCatalogue::Api.uri_for_object(soap_input)
        sin.has_description = BioCatalogue::Util.field_or_annotation_has_value?(soap_input, :description)
        sin.has_tag = BioCatalogue::Util.field_or_annotation_has_value?(soap_input, :tag)
        sin.has_example = BioCatalogue::Util.field_or_annotation_has_value?(soap_input, :example_data)
        
        sop.inputs << sin
        
        @stats.resources.soap_inputs << sin
      end
      
      soap_operation.soap_outputs.each do |soap_output|
        sout = Hashie::Mash.new
        sout.id = soap_output.id
        sout.name = BioCatalogue::Util.display_name(soap_output)
        sout.url = BioCatalogue::Api.uri_for_object(soap_output)
        sout.has_description = BioCatalogue::Util.field_or_annotation_has_value?(soap_output, :description)
        sout.has_tag = BioCatalogue::Util.field_or_annotation_has_value?(soap_output, :tag)
        sout.has_example = BioCatalogue::Util.field_or_annotation_has_value?(soap_output, :example_data)
        
        sop.outputs << sout
        
        @stats.resources.soap_outputs << sout
      end
      
      h.operations << sop
      
      @stats.resources.soap_services << sop
    end
    
    return h
  end
  
  def more_stats_hash_for_rest_service(rest_service)
    h = Hashie::Mash.new
    
    h.has_description = BioCatalogue::Util.field_or_annotation_has_value?(rest_service, :description)
    
    h.methods = [ ]
    
    rest_service.rest_methods.each do |rest_method|
      rm = Hashie::Mash.new
      rm.id = rest_method.id
      rm.name = BioCatalogue::Util.display_name(rest_method)
      rm.url = BioCatalogue::Api.uri_for_object(rest_method)
      rm.has_description = BioCatalogue::Util.field_or_annotation_has_value?(rest_method, :description)
      rm.has_tag = BioCatalogue::Util.field_or_annotation_has_value?(rest_method, :tag)
      rm.has_example = BioCatalogue::Util.field_or_annotation_has_value?(rest_method, :example_endpoint)
      
      rm.input_parameters = [ ]
      rm.input_representations = [ ]
      rm.output_parameters = [ ]
      rm.output_representations = [ ]
      
      rest_method.request_parameters.each do |rest_parameter|
        rinp = Hashie::Mash.new
        rinp.id = rest_parameter.id
        rinp.name = BioCatalogue::Util.display_name(rest_parameter)
        rinp.url = BioCatalogue::Api.uri_for_object(rest_parameter)
        rinp.has_description = BioCatalogue::Util.field_or_annotation_has_value?(rest_parameter, :description)
        rinp.has_tag = BioCatalogue::Util.field_or_annotation_has_value?(rest_parameter, :tag)
        rinp.has_example = BioCatalogue::Util.field_or_annotation_has_value?(rest_parameter, :example_data)
        
        rm.input_parameters << rinp
        
        @stats.resources.rest_parameters << rinp
      end
      
      rest_method.request_representations.each do |rest_representation|
        rinrep = Hashie::Mash.new
        rinrep.id = rest_representation.id
        rinrep.name = BioCatalogue::Util.display_name(rest_representation)
        rinrep.url = BioCatalogue::Api.uri_for_object(rest_representation)
        rinrep.has_description = BioCatalogue::Util.field_or_annotation_has_value?(rest_representation, :description)
        rinrep.has_tag = BioCatalogue::Util.field_or_annotation_has_value?(rest_representation, :tag)
        rinrep.has_example = BioCatalogue::Util.field_or_annotation_has_value?(rest_representation, :example_data)
        
        rm.input_representations << rinrep
        
        @stats.resources.rest_representations << rinrep
      end
      
      rest_method.response_parameters.each do |rest_parameter|
        routp = Hashie::Mash.new
        routp.id = rest_parameter.id
        routp.name = BioCatalogue::Util.display_name(rest_parameter)
        routp.url = BioCatalogue::Api.uri_for_object(rest_parameter)
        routp.has_description = BioCatalogue::Util.field_or_annotation_has_value?(rest_parameter, :description)
        routp.has_tag = BioCatalogue::Util.field_or_annotation_has_value?(rest_parameter, :tag)
        routp.has_example = BioCatalogue::Util.field_or_annotation_has_value?(rest_parameter, :example_data)
        
        rm.output_parameters << routp
        
        @stats.resources.rest_parameters << routp
      end
      
      rest_method.response_representations.each do |rest_representation|
        routrep = Hashie::Mash.new
        routrep.id = rest_representation.id
        routrep.name = BioCatalogue::Util.display_name(rest_representation)
        routrep.url = BioCatalogue::Api.uri_for_object(rest_representation)
        routrep.has_description = BioCatalogue::Util.field_or_annotation_has_value?(rest_representation, :description)
        routrep.has_tag = BioCatalogue::Util.field_or_annotation_has_value?(rest_representation, :tag)
        routrep.has_example = BioCatalogue::Util.field_or_annotation_has_value?(rest_representation, :example_data)
        
        rm.output_representations << routrep
        
        @stats.resources.rest_representations << routrep
      end
      
      h.methods << rm
      
      @stats.resources.rest_methods << rm
    end
    
    return h
  end
  
  def calculate_summary_total_for(resource_type_key, field)
    value = "Not calculated"
    
    # Check the first one of these resources to see if the field is applicable for this resource
    
    unless @stats.resources[resource_type_key].empty? or @stats.resources[resource_type_key].first[field].blank?
      if @stats.resources[resource_type_key].first[field] == NOT_APPLICABLE
        value = NOT_APPLICABLE
      else
        counter = Counter.new
      
        @stats.resources[resource_type_key].each do |r|
          if r[field] == true
            counter.increment
          end
        end
        
        value = counter.count
      end
    end
    
    return value
  end
  
end

module Util
  
  def self.format_value(value, total=nil)
    case value
      when Float
        if total and total.is_a? Numeric
          return "#{value.percent_of(total).round_with_precision(2)}%"
        end
    end
    
    return value.try(:to_s)
  end
  
end

puts Benchmark.measure {
  ServiceAnnotationReporter.new(ARGV.clone).run
}
