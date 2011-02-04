#!/usr/bin/env ruby

# Report on searches in the catalogue.

require 'pp'

env = "production"

unless ARGV[0].nil? or ARGV[0] == ''
  env = ARGV[0]
end

RAILS_ENV = env

# Load up the Rails app
require File.join(File.dirname(__FILE__), '..', '..', 'config', 'environment')

def report_stats
  stats = get_stats
  
  puts ""
  puts "Searches Report"
  puts "==============="
  puts ""
  
end

def get_stats
  stats = { }
  
  
  
  return stats
end


report_stats