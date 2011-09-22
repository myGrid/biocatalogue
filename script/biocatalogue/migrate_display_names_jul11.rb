#!/usr/bin/env ruby

# BioCatalogue: script/biocatalogue/update_display_names_jul11.rb
#
# Copyright (c) 2011, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# Migrates the now defunct display_name annotations

env = "production"

unless ARGV[0].nil? or ARGV[0] == ''
  env = ARGV[0]
end

RAILS_ENV = env

# Load up the Rails app
require File.join(File.dirname(__FILE__), '..', '..', 'config', 'environment')

count = 0

begin
  
  Annotation.record_timestamps = false
  
  Annotation.transaction do 
    Annotation.with_attribute_name('display_name').each do |a|
      annotatable = a.annotatable
      obj = nil
      
      case annotatable
        when Service
          obj = annotatable
        when SoapService
          obj = annotatable.service
      end
      
      unless obj.nil?
        obj.name = a.value_content
        obj.save!
        a.destroy
        count += 1
      end
    end
  end
  
  Annotation.record_timestamps = true
  
rescue Exception => ex
  puts ""
  puts "> ERROR: exception occured and transaction has been rolled back. Exception:"
  puts ex.message
  puts ex.backtrace.join("\n")
end

puts "> #{count} display names moved to the parent Service"
puts "> #{Annotation.with_attribute_name('display_name').count} display_name annotations remaining in the db"
