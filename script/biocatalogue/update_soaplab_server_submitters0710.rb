#!/usr/bin/env ruby

# BioCatalogue: script/biocatalogue/update_soaplab_server_submitters0710.rb
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# Note
# Before running this script, you should check that
# you have a file call soaplab_submmitters.rb in the 
# data directory under the application root.
# data/soaplab_submitters.rb

require 'optparse'
require 'data/soaplab_submitters'

class UpdateSoaplabServerSubmitters0710

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
    
    @submitter_for_server = SoaplabSubmitters.new().submitters
    
    # Start the Rails app
      
    ENV["RAILS_ENV"] = @options[:environment]
    RAILS_ENV.replace(@options[:environment]) if defined?(RAILS_ENV)
    
    require File.join(File.dirname(__FILE__), '..', '..', 'config', 'environment')
    
  end
  
  def update_submitter_for_server(server_url)
    submitter = User.find_by_email(@submitter_for_server[server_url])
    server    = SoaplabServer.find_by_location(server_url)
    if submitter && server
      unless server.submitter
        server.submitter = submitter
        server.save
        puts "updated submitter for soaplab server #{server.id} to #{submitter.display_name}"
      end
    end
  end

  def update( *params)
    begin
      options = params.extract_options!.symbolize_keys
      options[:server] ||= options.include?(:server)
      options[:all] ||= options.include?(:all)
      
      if options[:server]
        update_submitter_for_server options[:server] 
      elsif options[:all]
        SoaplabServer.find(:all).each do |sls|
          update_submitter_for_server sls.location
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

UpdateSoaplabServerSubmitters0710.new(ARGV.clone).update :all => true 

