#!/usr/bin/env ruby

# This script generate a reports about service statuses. It currently generates a
# list of link to failing tests. 
#
# NOTE : This script is intended for debugging purposes only
#
# Usage: monitoring_report [options]
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




class MonitoringReport
  
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
    stats = {:passed => [], :failed => [], :unchecked => [] }
    Service.all.each do |service|
      case service.latest_status.label
        when "PASSED"
          stats[:passed] << service.id
        when "UNCHECKED"
          stats[:unchecked] << service.id
        else
          stats[:failed] << service.id
      end
    end
    
    puts "Redirecting output of $stdout to log file: '{RAILS_ROOT}/log/update_soaplab_{current_time}.html' ..."
    $stdout = File.new(File.join(File.dirname(__FILE__), '..', '..', 'log', "monitoring_report_#{Time.now.strftime('%Y%m%d-%H%M')}.html"), "w")
    $stdout.sync = true
    
    puts "<html>"
    puts "<h3> Failing Services List Generated on #{Time.now}</h3>"
    puts "<hr/>"
    
    puts "<p> No of services that failed : #{stats[:failed].count }</p>"
    puts "<p>"
    stats[:failed].each do |failed|
      puts "<a href='#{SITE_BASE_HOST}/services/#{failed}'> #{SITE_BASE_HOST}/services/#{failed}</a> <br/>"
    end
    puts "</p>"
    puts "</html>"
    
    # Reset $stdout
    $stdout = STDOUT
  end
end


puts Benchmark.measure {
  MonitoringReport.new(ARGV.clone).run
}

