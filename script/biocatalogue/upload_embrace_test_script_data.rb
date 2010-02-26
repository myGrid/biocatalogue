
#!/usr/bin/env ruby


# This script uploads a test from the BioCatalogue database
# to a test server where the test can be executed.
# It uses the ruby interface to curl (curb) to upload the 
# the test script files. The url of the test is specified in a yaml
# file in the config directory.
#   
# Example: 
#
#
#
# Usage:  [options]
#
#    -e, --environment=name           Specifies the environment to run this import script under (test|development|production).
#                                     Default: development
#
#    -h, --help                       Show this help message
#
#    -t, --test                       Run the script in test mode (Do not upload any test, just show which are available for upload).
#
# 

#require 'zip/zip'
#require 'zip/zipfilesystem'
require 'rubygems'
require 'benchmark'
require 'optparse'
require 'yaml'
require 'curb'
require 'pp'


class UploadTestScript
  
  attr_accessor :options
  attr_accessor :settings
  
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
      
      opts.on("-t", "--test", "Run the script in test mode (Do not upload any test, just show which are available for upload).") { @options[:test] = true }
    
      opts.parse!
    end
    
    
    # Start the Rails app
      
    ENV["RAILS_ENV"] = @options[:environment]
    RAILS_ENV.replace(@options[:environment]) if defined?(RAILS_ENV)
    
    #require File.join(File.dirname(__FILE__), '..', '..', 'config', 'environment')
    require File.join('config', 'environment')
    
    #@settings = YAML::load_file(File.join('..', '..', 'config','initializers', 'test_scripts.yml'))
    @settings = YAML::load_file(File.join('config','initializers', 'test_scripts.yml'))
    
  end

  def run(*params)
    options = params.extract_options!.symbolize_keys
    options[:test_ids] ||= options.include?(:test_ids)
    options[:all] ||= options.include?(:all)
        
    if options[:test_ids] and options[:all]
      puts "Seems we have a configuration problem"
      puts "Do not know what to do! Please either either give a list of test ids to upload or tell me to upload all, NOT both"
      return
    end
        
    if not options[:test_ids] and not options[:all]
      puts "Please run"
      puts "UploadTestScript.new(ARGV.clone).run :all => true"
      puts "to upload all test that have not been activated yet OR"
      puts "UploadTestScript.new(ARGV.clone).run :test_ids => [some, test, ids]"
      puts "to uplaod test scripts with the given ids"
      return
    end
    
    if @options[:test]
      puts ""
      puts "********************************************************************"
      puts "NOTE: Running in test mode. No test are uploaded "
      puts "********************************************************************"
      exit
    end
    
    Service.transaction do 
      if options[:test_ids]
        test_scripts = TestScript.find(options[:test_ids]).compact
        upload_tests(test_scripts)
      elsif options[:all]
        puts "uploading all tests scripts to test server..."
        Service.find(:all).each do |service|
          upload_tests(service.test_scripts)
        end
      end
    end
  end
  
  private
  
  # upload test data to the url given in
  # the config/test_scripts.yml
  def upload_tests(test_scripts =[])
    test_scripts.each do |test_obj|
      begin
        if test_obj.activated_at.nil?
          data = ContentBlob.find(test_obj.content_blob_id).data
          data_file = File.new(test_obj.filename, 'wb')
          data_file.puts(data)
          data_file.close
          c = Curl::Easy.new(@settings[@options[:environment]]["upload_url"])
          c.multipart_form_post =true
          c.http_post(Curl::PostField.content('embrace_test_script[operation]',test_obj.exec_name),
                Curl::PostField.content('embrace_test_script[prog_language]',test_obj.prog_language),
                Curl::PostField.content('embrace_test_script[biocat_test_id]',test_obj.id.to_s),
                        Curl::PostField.content('commit','Create'),
                        Curl::PostField.file("test_file", test_obj.filename))
          test_obj.activated_at = Time.now
          test_obj.save!
          puts "Test with id #{test_obj.id} has been posted to #{@settings[@options[:environment]]["upload_url"]}"
        else
          puts "Test with id #{test_obj.id} has already been activated. Not uploaded..."
        end
      rescue Curl::Err::ConnectionFailedError => ex
        puts "Could not connect to remote server! The server may not be running. " 
        puts "Please also check that #{@settings[@options[:environment]]["upload_url"]} "
        puts "is the correct URL to the remote server"
      rescue => ex
        puts "ERROR : There was an exception while transferring test data "
        puts "#{@settings[@options[:environment]]["upload_url"]}"
        puts ex.backtrace
      end
    end
  end   
end

# Redirect $stdout to log file
puts "Redirecting output of $stdout to log file: tmp/pids/upload_test_script.log ..."
puts "You should run this from the application base directory"

$stdout = File.new(File.join('tmp','pids','test_scripts.log'), 'w')
$stdout.sync = true

puts Benchmark.measure { UploadTestScript.new(ARGV.clone).run :all => true }

# Reset $stdout
$stdout = STDOUT