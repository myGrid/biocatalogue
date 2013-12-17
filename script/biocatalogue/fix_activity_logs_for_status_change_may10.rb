#!/usr/bin/env ruby

# BioCatalogue: script/biocatalogue/fix_activity_logs_for_status_change_may10.rb
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

environment = (ARGV[0].nil? || ARGV[0]=='' ? "development" : ARGV[0])
RAILS_ENV = environment

# Load up the Rails app
require File.join(File.dirname(__FILE__), '..', '..', 'config', 'environment')

begin
  
  ActivityLog.record_timestamps = false
  
  ActivityLog.transaction do 
    
    ActivityLog.all(:conditions => { :action => 'status_change' }).each do |al|
      if al.activity_loggable and al.referenced_id.nil?
        al.referenced = al.activity_loggable.service
        al.save!
      end
    end
    
  end
  
  ActivityLog.record_timestamps = true
  
rescue Exception => ex
  puts ""
  puts "> ERROR: exception occured and transaction has been rolled back. Exception:"
  puts ex.message
  puts ex.backtrace.join("\n")
end