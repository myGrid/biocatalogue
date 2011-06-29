#!/usr/bin/env ruby

# Report on API usage.

require 'pp'

require File.join(File.dirname(__FILE__), 'shared', 'numbers_util')

include NumbersUtil

env = "production"

unless ARGV[0].nil? or ARGV[0] == ''
  env = ARGV[0]
end

RAILS_ENV = env

# Load up the Rails app
require File.join(File.dirname(__FILE__), '..', '..', 'config', 'environment')

@@formats = [ :xml, :json, :atom ]

def report_stats
  stats = get_stats
  
  puts ""
  puts "API Usage Report"
  puts "================"
  puts ""
  
  output_format_1 = "%25s\t%9s\n"
  printf(output_format_1, "Requests (All):", number_with_delimiter(stats[:counts][:total]))
  @@formats.each do |f|
    printf(output_format_1, "Requests (#{f.to_s.upcase}):", number_with_delimiter(stats[:counts][f]))
  end
  puts ""
  printf(output_format_1, "Requests (from Taverna):", number_with_delimiter(stats[:counts][:taverna]))
  
  puts ""
  puts "Top 20 XML and JSON accesses:"
  puts ""
  
  popular_resources_action_length_max = stats[:resources][:popular].map {|s| s['action'].length}.max.to_i
  output_format_2 = "%#{popular_resources_action_length_max}s\t%9s\n"
  stats[:resources][:popular].each do |r|
    printf(output_format_2, r['action'], number_with_delimiter(r['count'])) 
  end
end

def get_stats
  stats = { }
  
  stats[:counts] = { }
  
  stats[:counts][:total] = ActivityLog.count(:all, :conditions => { :format => @@formats.map {|f| f.to_s } })
  stats[:counts][:xml] = ActivityLog.count(:all, :conditions => { :format => "xml" })
  stats[:counts][:json] = ActivityLog.count(:all, :conditions => { :format => "json" })
  stats[:counts][:atom] = ActivityLog.count(:all, :conditions => { :format => "atom" })
  
  stats[:counts][:taverna] = ActivityLog.count(:all, :conditions => "format IN ('xml', 'json') AND activity_logs.format = 'xml' AND user_agent LIKE 'Taverna2%'")
  
  stats[:resources] = { }
  
  popular_resources_sql = "SELECT action, COUNT(*) AS count 
                          FROM activity_logs
                          WHERE format IN ('xml', 'json')
                          GROUP BY action
                          ORDER BY COUNT(*) DESC
                          LIMIT 20"
                   
  stats[:resources][:popular] = ActiveRecord::Base.connection.select_all(popular_resources_sql) 
  
  return stats
end

report_stats