#!/usr/bin/env ruby

# BioCatalogue: script/biocatalogue/update_providers_sep09.rb
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# Updates the providers table to rename the "name" fields to the new scheme (September 2009)
# eg: "ebi.ac.uk" will become "ebi-ac-uk"

env = "production"

unless ARGV[0].nil? or ARGV[0] == ''
  env = ARGV[0]
end

RAILS_ENV = env

# Load up the Rails app
require File.join(File.dirname(__FILE__), '..', '..', 'config', 'environment')

begin
  
  ServiceProvider.record_timestamps = false
  
  ServiceProvider.transaction do 
    
    ServiceProvider.all.each do |p|
      
      p.name = p.name.gsub(".", "-")
      p.save!
      
    end
    
  end
  
  ServiceProvider.record_timestamps = true
  
rescue Exception => ex
  puts ""
  puts "> ERROR: exception occured and transaction has been rolled back. Exception:"
  puts ex.message
  puts ex.backtrace.join("\n")
end
