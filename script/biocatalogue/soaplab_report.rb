#!/usr/bin/env ruby

# This script generate a report about the Soaplab services in the catalogue.
#
# Usage: soaplab_report [options]
#
#    -e, --environment=name           Specifies the environment to run this script under (test|development|production).
#                                     Default: production
#
#    -h, --help                       Show this help message.
#
# Dependencies:
# - Rails (v2.3.2)

require 'optparse'
require 'benchmark'

require File.join(File.dirname(__FILE__), 'shared', 'numbers_util')

include NumbersUtil

class SoaplabReport
  
  attr_accessor :options, :stats
  
  def initialize(args)
    @options = {
      :environment => (ENV['RAILS_ENV'] || "production").dup,
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
    
    @stats = { }
    @stats[:soaplab_servers] = [ ]
    @stats[:services] = [ ]
    @stats[:soap_operations] = [ ]
  end  
  
  def run
    @stats[:soaplab_servers] = SoaplabServer.all
    
    Service.all.each do |service|
      is_soaplab = false
      
      # First check if an associated SoaplabServer object exist
      if service.soaplab_server
        is_soaplab = true
      else
        # Then check if the "soaplab" tag has been applied
        tag_annotations = BioCatalogue::Annotations::get_tag_annotations_for_annotatable(service)
        is_soaplab = true if tag_annotations.map{|a| a.value}.compact.map{|b| b.downcase}.include?("soaplab")
      end
      
      if is_soaplab
        @stats[:services] << service
        soap_services = service.service_version_instances_by_type("SoapService")
        unless soap_services.empty?
          soap_services.each do |soap_service|
            @stats[:soap_operations].push(*soap_service.soap_operations)
          end
        end
      end
    end
    
    write_report
  end
  
  def write_report
    puts "Redirecting output of $stdout to log file: '{RAILS_ROOT}/log/soaplab_report_{current_time}.html' ..."
    $stdout = File.new(File.join(File.dirname(__FILE__), '..', '..', 'log', "soaplab_report_#{Time.now.strftime('%Y%m%d-%H%M')}.txt"), "w")
    $stdout.sync = true
    
    puts ""
    puts "Soaplab Report"
    puts "=============="
    puts ""
    
    output_format_1 = "%25s\t%9s\n"
    
    printf(output_format_1, "Soaplab servers:", number_with_delimiter(stats[:soaplab_servers].length))
    printf(output_format_1, "Web services that are Soaplab tools:", number_with_delimiter(stats[:services].length))
    printf(output_format_1, "Total SOAP operations on Soaplab services", number_with_delimiter(stats[:soap_operations].length))
    
    # Reset $stdout
    $stdout = STDOUT
  end
end


puts Benchmark.measure {
  SoaplabReport.new(ARGV.clone).run
}