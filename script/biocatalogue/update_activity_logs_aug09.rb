#!/usr/bin/env ruby

# BioCatalogue: script/biocatalogue/update_activity_logs_aug09.rb
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# Updates the activity_logs table for the addition of new fields in August 2009

env = "production"

unless ARGV[0].nil? or ARGV[0] == ''
  env = ARGV[0]
end

RAILS_ENV = env

# Load up the Rails app
require File.join(File.dirname(__FILE__), '..', '..', 'config', 'environment')

begin
  
  ActivityLog.record_timestamps = false
  
  ActivityLog.transaction do 
    
    ActivityLog.all.each do |a|
      
      unless a.data.blank?
        
        puts ""
        puts "> Processing ActivityLog with ID: #{a.id}"
        
        if a.data.has_key? "http_referer"
          puts ">> Moving 'http_referer' from 'data' to it's own field..."
          a.http_referer = a.data["http_referer"]
          a.data.delete("http_referer")
        end
        
        if a.data.has_key? "http_user_agent"
          puts ">> Moving 'http_user_agent' from 'data' to it's own field..."
          a.user_agent = a.data["http_user_agent"]
          a.data.delete("http_user_agent")
        end
        
        a.save!
        
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
