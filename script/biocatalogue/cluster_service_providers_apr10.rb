#!/usr/bin/env ruby

# BioCatalogue: script/biocatalogue/cluster_service_providers_apr10.rb
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

require 'csv'
require 'benchmark'

environment = (ARGV[0].nil? || ARGV[0]=='' ? "development" : ARGV[0])
RAILS_ENV = environment

class UpdateServiceProviderRelationships

  attr_accessor :service_providers
  
  # ====================
  
  def initialize
    # Start the Rails app
    require File.join(File.dirname(__FILE__), '..', '..', 'config', 'environment')
    
    
    # add the path to the gems in vendor/gems
    Gem.path << "#{Rails.root}/vendor/gems" if defined?(Rails.root)
    Gem.source_index.refresh!
        
    # load up CSV data file
    @service_providers = {}
    # Specify the path to the CSV data file in here
    csv_file_path = "#{Rails.root}/data/service-providers.csv"
    load_service_providers_from_csv_file(csv_file_path)
  end

  # ====================

  def update
    puts "", "Iterating Service Providers...", "", "==============================", ""
    @sp_cluster_names = []
    
    ServiceProvider.all.each do |sp|
      provider_name = (@service_providers[sp.name] || sp.name)

      if sp.service_deployments.blank? # service provider has no services
        # delete service provider
        puts "Deleting Orphaned Service Provider: #{sp.inspect}" 
        sp.destroy
        next
      else # service provider has services
        cluster_service_provider(sp, provider_name)
        puts "", "------------------------------", ""
      end # if else
    end # ServiceProvider.all.each
    
    # clean out display name annotations
    remove_service_provider_display_name_annotations
    
    puts "==============================", "", "Clustering completed."
  end
  
  # ====================
  
  private
  
  def load_service_providers_from_csv_file(csv_file_path)
    begin
      print "\nReading CSV data file... "
      CSV::Reader.parse(File.open(csv_file_path, 'r')) { |row|        
        hostname, provider = row[0], row[1]        

        next if hostname=="Internal Identifier" && provider=="Who?"
        next if hostname.blank? || provider.blank?
        
        @service_providers.merge!(hostname.strip => provider.strip)
      }

      puts "Done!\n"
    rescue Exception => ex
      puts "Error reading CSV document!"
      puts "Exception: " + ex.class.name
      puts ex.message, ex.backtrace.join("\n"), "", "Aborting!"
      exit
    end
  end
  
  # ====================
  
  def cluster_service_provider(sp, provider_name)
    begin
      host = Addressable::URI.parse(sp.service_deployments.first.endpoint).host
      sp_hostname = ServiceProviderHostname.find_or_initialize_by_hostname(host)
      
      if @sp_cluster_names.include?(provider_name) # cluster has been used in script
        puts "Hostname '#{host}'", "Linking with Service Provider '#{provider_name}'", ""
        master = ServiceProvider.find_by_name(provider_name)

        # merge this Service Provider into the Master Service Provider
        sp.merge_into(master, :print_log => true, :migrate_hostnames => false)
        
        sp_hostname.service_provider_id = master.id
      else # cluster has not been used in script
        puts "Hostname '#{host}'", "Updating Service Provider name from '#{sp.name}' to '#{provider_name}'"
        sp.name = provider_name
        sp.save!

        @sp_cluster_names << provider_name

        sp_hostname.service_provider_id = sp.id
        master = sp
      end
    
      sp_hostname.save!
      puts "", master.inspect, sp_hostname.inspect
    rescue Exception => ex
      puts "Error linking hostname #{host} with Service Provider #{provider_name}"
      puts "Exception: " + ex.class.name + " - " + ex.message
      puts ex.backtrace.join("\n")
    ensure
      master = nil
    end
  end

  # ====================
 
  def remove_service_provider_display_name_annotations
    puts "Destroying display name annotations for Service Providers... " # change to print
    anns = Annotation.with_attribute_name('display_name').find_all_by_annotatable_type("ServiceProvider")
    anns.each{ |a|
      a.destroy
      puts a.inspect
    }
  end
end

# ========================================

# Redirect $stdout to log file
puts "Redirecting output of $stdout to log file: '{Rails.root}/log/update_service_providers_{current_time}.log' ..."
$stdout = File.new(File.join(File.dirname(__FILE__), '..', '..', 'log', "update_service_providers_#{Time.now.strftime('%Y%m%d-%H%M')}.log"), "w")
$stdout.sync = true

puts Benchmark.measure { UpdateServiceProviderRelationships.new.update }

# Reset $stdout
$stdout = STDOUT

