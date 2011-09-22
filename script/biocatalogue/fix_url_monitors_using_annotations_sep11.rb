#!/usr/bin/env ruby

# BioCatalogue: script/biocatalogue/fix_url_monitors_using_annotations_sep11.rb
#
# Copyright (c) 2011, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# Fixes the URL monitors that use Annotations as the source of the URL to monitor.
# This is to take into account the changes in the Annotations plugin to make
# the 'value' of an annotation a polymorphic object instead of just a String.

env = "production"

unless ARGV[0].nil? or ARGV[0] == ''
  env = ARGV[0]
end

RAILS_ENV = env

# Load up the Rails app
require File.join(File.dirname(__FILE__), '..', '..', 'config', 'environment')

count = 0

begin
  
  UrlMonitor.record_timestamps = false
  
  UrlMonitor.transaction do 
    UrlMonitor.find(:all, :conditions => { :parent_type => "Annotation", :property => "value" }).each do |u|
      u.property = "value_content"
      u.save!
      count += 1
    end
  end
  
  UrlMonitor.record_timestamps = true
  
rescue Exception => ex
  puts ""
  puts "> ERROR: exception occured and transaction has been rolled back. Exception:"
  puts ex.message
  puts ex.backtrace.join("\n")
end

puts "> #{count} URL monitors updated"