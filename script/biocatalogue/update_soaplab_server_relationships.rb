#!/usr/bin/env ruby

# BioCatalogue: /update_soaplab_server_relationships.rb
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details


require 'benchmark'
require 'optparse'


class UpdateSoaplabServerRelationships


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
      
      opts.on("-t", "--test", "Run the script in test mode (so won't actually store anything in the database).") { @options[:test] = true }
    
      opts.parse!
    end
    
    
    # Start the Rails app
      
    ENV["RAILS_ENV"] = @options[:environment]
    RAILS_ENV.replace(@options[:environment]) if defined?(RAILS_ENV)
    
    require File.dirname(__FILE__) + '/config/environment'
    
  end
  
  # find registered soaplab services that are not associated with the
  # server instance througth the relationship mechanism. Update the 
  # the relationship table and tag these services with 'soaplab' and their
  # 'group name' where they are not already tagged.
  def update_relationships(url)
    soaplab = SoaplabServer.find_by_location(url)
    data    = soaplab.services_factory().values.flatten
    wsdls_from_server  = data.collect{ |item| item["location"]}
    registered_soaps   = SoapService.find_all_by_wsdl_location(wsdls_from_server).compact
    registered_wsdls   = registered_soaps.collect{|s| s.wsdl_location}
    wsdls_from_relationships = soaplab.services.collect{|service| service.latest_version.service_versionified.wsdl_location}
    wsdls_to_add    = registered_wsdls - wsdls_from_relationships 
    submitter       = nil
    unless soaplab.services.empty?
      submitter       = User.find(soaplab.services.first.submitter_id)
    end
    
    
    soaps_to_add    = SoapService.find_all_by_wsdl_location(wsdls_from_server).compact
    services_to_add = soaps_to_add.collect{|s| s.service}
    puts "server : #{url}"
    puts "No of relationships to add #{wsdls_to_add.length}"
    puts wsdls_to_add
    unless wsdls_to_add.empty?
      if submitter.nil?
        submitter = User.find(SoapService.find_by_wsdl_location(wsdls_to_add.first).service.submitter_id)
      end
      soaplab.create_relationships(wsdls_to_add)
      create_tags_if_not_exist(services_to_add, submitter)
    end
  end
  
  def create_tags_if_not_exist(services, user)
    
    services.each do |service|
      begin
        soaplab.create_tags([service], user)
        puts "success... tags created!"
      rescue ActiveRecord::RecordInvalid => ex
        puts "Exception in creating tags...record invalid or may already exist"
        puts ex.backtrace
      rescue Exception => ex
        puts "could not create tag"
        puts ex.backtrace
      end
    end
  end


  def update( *params)
    options = params.extract_options!.symbolize_keys
    options[:server] ||= options.include?(:server)
    options[:all] ||= options.include?(:all)
    
    if options[:server]
      update_relationships options[:server] 
    elsif options[:all]
      SoaplabServer.find(:all).each do |sls|
        update_relationships sls.location
      end
    else
      puts "No valid option configured"
    end
  end


end


# Redirect $stdout to log file
puts "Redirecting output of $stdout to log file: update_soaplab_server_relationships.log ..."
$stdout = File.new("update_soaplab_server_relationships.log", "w")
$stdout.sync = true

#puts Benchmark.measure { UpdateSoaplabServerRelationships.new(ARGV.clone).update :server => "http://bioinformatics.istge.it:8080/axis/services/AnalysisFactory?wsdl" }
puts Benchmark.measure { UpdateSoaplabServerRelationships.new(ARGV.clone).update :all => true }

# Reset $stdout
$stdout = STDOUT

