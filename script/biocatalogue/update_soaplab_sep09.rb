#!/usr/bin/env ruby

# BioCatalogue: script/biocatalogue/update_soaplab_sep09.rb
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

#require 'soap4r'
require 'benchmark'
require 'optparse'
#require 'soap/wsdlDriver'
require 'ftools'



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
    
    require File.join(File.dirname(__FILE__), '..', '..', 'config', 'environment')
    
    # add the path to the gems in vendor/gems so that 
    # the soapr4 gem which is required for this script to work
    # will be found. Other wise the script will throw some SOAP exception due
    # to use of the soap4r library packaged with ruby
    Gem.path << "#{Rails.root}/vendor/gems" if defined?(Rails.root)
    Gem.source_index.refresh!
    
    # load up soap4r gem and the wsdl driver
    gem 'soap4r'
    require 'soap/wsdlDriver'
    
  end
  
  # find registered soaplab services that are not associated with the
  # server instance througth the relationship mechanism. Update the 
  # the relationship table and tag these services with 'soaplab' and their
  # 'group name' where they are not already tagged.
  def update_soaplab_server(url)
    soaplab = SoaplabServer.find_by_location(url)
    data    = soaplab.services_factory().values.flatten
    wsdls_from_server  = data.collect{ |item| item["location"]}
    registered_soaps   = SoapService.find_all_by_wsdl_location(wsdls_from_server).compact
    registered_wsdls   = registered_soaps.collect{|s| s.wsdl_location}
    wsdls_from_relationships = soaplab.services.collect{|service| service.latest_version.service_versionified.wsdl_location}
    wsdls_to_add    = registered_wsdls - wsdls_from_relationships 
    submitter       = nil
    unless soaplab.services.empty?
      submitter = User.find(soaplab.services.first.submitter_id)
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
    if soaplab.endpoint.nil?
      proxy_info       = get_endpoint_and_name(url)
      unless proxy_info.empty?
        soaplab.endpoint = proxy_info[0] 
        soaplab.name     = proxy_info[1]
        soaplab.save
      end
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
  
  def get_endpoint_and_name(wsdl)
    proxy = nil
    proxy = SOAP::WSDLDriverFactory.new(wsdl).create_rpc_driver
    unless proxy.nil?
      return File.split(proxy.endpoint_url)
    end
    return []
  end


  def update( *params)
    begin
      options = params.extract_options!.symbolize_keys
      options[:server] ||= options.include?(:server)
      options[:all] ||= options.include?(:all)
      
      if options[:server]
        update_soaplab_server options[:server] 
      elsif options[:all]
        SoaplabServer.find(:all).each do |sls|
          update_soaplab_server sls.location
        end
      else
        puts "No valid option configured"

      end
    rescue Exception => ex
      puts ""
      puts ">> ERROR: exception occured. Exception: #{ex.class.name} - "
      puts ex.message
      puts ex.backtrace.join("\n")
    end

    
  end


end


# Redirect $stdout to log file
puts "Redirecting output of $stdout to log file: '{Rails.root}/log/update_soaplab_{current_time}.log' ..."
$stdout = File.new(File.join(File.dirname(__FILE__), '..', '..', 'log', "update_soaplab_#{Time.now.strftime('%Y%m%d-%H%M')}.log"), "w")
$stdout.sync = true

#puts Benchmark.measure { UpdateSoaplabServerRelationships.new(ARGV.clone).update :server => "http://bioinformatics.istge.it:8080/axis/services/AnalysisFactory?wsdl" }
puts Benchmark.measure { UpdateSoaplabServerRelationships.new(ARGV.clone).update :all => true }

# Reset $stdout
$stdout = STDOUT

