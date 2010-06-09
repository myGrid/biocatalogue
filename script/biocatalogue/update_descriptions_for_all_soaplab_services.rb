#!/usr/bin/env ruby

# This script will lunch background jobs, one for each soaplab service, 
# that will update the description of the service by calling the describe
# operation implemented by soaplab services
#
# Usage: update_descriptions_for_all_soaplab_services.rb [options]
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

class UpdateSoaplabServiceDescriptions
  
  attr_accessor :options
  
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
  end  
  
  def run
    SoaplabServer.all.each do |server|
      server.update_descriptions_from_soaplab!
    end
  end
end


puts Benchmark.measure {
  UpdateSoaplabServiceDescriptions.new(ARGV.clone).run
}

