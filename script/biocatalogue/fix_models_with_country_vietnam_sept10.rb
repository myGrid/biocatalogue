#!/usr/bin/env ruby

# BioCatalogue: script/biocatalogue/fix_models_with_county_vietnam_sept10.rb
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

require 'benchmark'

environment = (ARGV[0].nil? || ARGV[0]=='' ? "development" : ARGV[0])
RAILS_ENV = environment

class UpdateModelCountryValues
  
  def initialize
    # Start the Rails app
    require File.join(File.dirname(__FILE__), '..', '..', 'config', 'environment')
    
    
    # add the path to the gems in vendor/gems
    Gem.path << "#{RAILS_ROOT}/vendor/gems" if defined?(RAILS_ROOT)
    Gem.source_index.refresh!
  end

  # ====================

  def update
    models = [ ServiceDeployment, User ]
    
    puts "", "Updating Model...", "", "=============================="
    
    models.each do |model|
      model.transaction do
        puts "", "#{model.name}:", ""
        
        model.find_all_by_country("Viet Nam").each { |item|
          puts "Updating: #{item.inspect}", ""
          item.country = "Vietnam"
          item.save!
        }
        
        puts "=============================="
      end
    end
    
    puts "", "Update completed.", ""
  end
  
end

# ========================================

# Redirect $stdout to log file
puts "Redirecting output of $stdout to log file: '{RAILS_ROOT}/log/fix_models_with_county_vietnam_{current_time}.log' ..."
$stdout = File.new(File.join(File.dirname(__FILE__), '..', '..', 'log', "fix_models_with_county_vietnam_#{Time.now.strftime('%Y%m%d-%H%M')}.log"), "w")
$stdout.sync = true

puts Benchmark.measure { UpdateModelCountryValues.new.update }

# Reset $stdout
$stdout = STDOUT

