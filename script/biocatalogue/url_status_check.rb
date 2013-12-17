#!/usr/bin/env ruby

# This script attempts to access urls and record the statuses
# in the test_results table.  The script does the following checks:
# 1) It sends a HEAD request to get the header of a url
# 2) It sends an XML to a SOAP endpoint and checks if it get XML back
# 3) TODO : Check if the xml is a valid soap fault
# 
#
# This scripts records simple online/offline status. Only urls that generate the
# an HTTP 200 status code are considered to be online. If the stutus cannot be determined
# because of some condition like a timeout, the test result is set to 1, meanining warning. A debug message is
# also added where possible.

# IMPORTANT: This scripts uses the curl system command. 


# Usage: update_url_monitors [options]
#
#    -e, --environment=name           Specifies the environment to run this import script under (test|development|production).
#                                     Default: development
#
#    -h, --help                       Show this help message.
#
#    -t, --test                       Run the script in test mode (so won't actually store anything in the db and will only go through one keyword and one tag).
#
# 

require 'benchmark'
require 'optparse'
#require 'rexml/document'
#include REXML


class CheckUrlStatus


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
      
      opts.on("-t", "--test", "Run the script in test mode (so won't actually store anything, just the status of the test will be given).") { @options[:test] = true }
    
      opts.parse!
    end
    
    
    # Start the Rails app
      
    ENV["RAILS_ENV"] = @options[:environment]
    RAILS_ENV.replace(@options[:environment]) if defined?(RAILS_ENV)
    
    require File.dirname(__FILE__) + '/config/environment'
    
  end


  # this function get the HTTP head from a url using curl
  # and checks the status code. OK if status code is 200, warning otherwise
  # eg curl -I http://www.google.com
  # Note : this only works on a system with curl system command

  def check_url_status(url)
    puts "checking url #{url}"
    status = {:action => 'http_head'}
    data = %x[curl -I --max-time 20 #{url}]
  
    pieces = data.split
    if pieces[1] =='200' and pieces[2] =='OK'   # status OK
      status.merge!({:result=> 0, :message => data})
    elsif pieces[1] =='302'                     # redirect means OK
      status.merge!({:result=> 0, :message => data})
    else 
      status.merge!({:result=> 1, :message => data})
    end
    
  return status 
  end

  # Generate a soap fault by sending a non-intrusive xml to the service endpoint
  # then parse the soap message to see if the service implements soap correctly
  #curl --header "Content-Type: text/xml" --data "<?xml version="1.0"?>...." http://opendap.co-ops.nos.noaa.gov/axis/services/Predictions
  def generate_soap_fault(endpoint)
    puts "checking endpoint #{endpoint}"
    status = {:action => 'soap_fault'}
    data = %x[curl --max-time 20 --header "Content-Type: text/xml" --data "<?xml version="1.0"?>" #{endpoint}]
  
    pieces = data.split
    if pieces[0] == '<?xml'
      status.merge!({:result=> 0, :message => data})
    else
      status.merge!({:result=> 1, :message => data})
    end
    return status
  end

  def check( *params)
    options = params.extract_options!.symbolize_keys
    options[:url] ||= options.include?(:url)
    options[:soap_endpoint] ||= options.include?(:soap_endpoint)
    
    if options[:url]
      check_url_status options[:url]
    elsif options[:soap_endpoint]
      generate_soap_fault options[:soap_endpoint] 
    else
      puts "No valid option selected"
    end
  end

  # TODO
  # Validate the soap fault xml fragment
  # to verify if soap was implemented correctly

#  def process_soap_fault(data)
#    doc = Document.new(data)
#    doc
#  end


  def run
    
    if @options[:test]
      puts ""
      puts "**************************************************************"
      puts "NOTE: Running in test mode. No saves will be made to the DB"
      puts "*************************************************************"
    end
    

    UrlMonitor.all.each do |monitor|
      # get all the attributes of the services to be monitors
      # and run the checks agains them
      result = {}
      pingable = UrlMonitor.find_parent(monitor.parent_type, monitor.parent_id)
    
      if monitor.property =="endpoint" and pingable.service_version.service_versionified_type =="SoapService"
        # eg: check :soap_endpoint => pingable.endpoint
        result = check :soap_endpoint => pingable.send(monitor.property)
      else
        # eg: check :url => pingable.wsdl_location
        result = check :url => pingable.send(monitor.property)
      end
    
      # create a test result entry in the db to record
      # the current check for this URL/endpoint
      tr = TestResult.new(:test_id => monitor.id,
                        :test_type => monitor.class.to_s,
                        :result => result[:result],
                        :action => result[:action],
                        :message => result[:message] )
      if !@options[:test]
        if tr.save!
          puts "Result for monitor id:  #{monitor.id} saved!"
        else
          puts "Ooops! Result for monitor id:  #{monitor.id} could not be saved!"
        end
      else
        if result[:result] == 0
          puts "Test  : OK"
        else
          puts "Test  : ERROR"
        end
      end
    end
  end

end


# Redirect $stdout to log file
puts "Redirecting output of $stdout to log file: url_status_check.log ..."
$stdout = File.new("url_status_check.log", "w")
$stdout.sync = true

puts Benchmark.measure { CheckUrlStatus.new(ARGV.clone).run }

# Reset $stdout
$stdout = STDOUT

