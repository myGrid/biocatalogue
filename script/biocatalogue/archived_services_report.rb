#!/usr/bin/env ruby

# Report on archived services in the catalogue.

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
  puts "Archived Services Report"
  puts "========================"
  puts ""
  
  puts "#{stats[:counts][:archived]} out of #{stats[:counts][:total]} services are archived"
  puts ""
  
  puts ""
  puts "By Providers:"
  puts ""
  
  provider_name_length_max = stats[:providers].map {|p| p['name'].length}.max.to_i
  format = "%#{provider_name_length_max}s\t%s\n"
  printf(format, "Provider", "Count")
  printf(format, '-' * provider_name_length_max, '-----')
  stats[:providers].each do |p|
    printf(format, p['name'], p['count'])
  end
end

def get_stats
  stats = { }
  
  stats[:counts] = { }
  stats[:counts][:total] = Service.count
  stats[:counts][:archived] = Service.count(:conditions => "archived_at IS NOT NULL")
  
  providers_sql = "SELECT service_providers.name AS name, COUNT(*) AS count 
                   FROM service_deployments
                   INNER JOIN services ON services.id = service_deployments.service_id
                   INNER JOIN service_providers ON service_providers.id = service_deployments.service_provider_id
                   WHERE services.archived_at IS NOT NULL
                   GROUP BY service_providers.id
                   ORDER BY COUNT(*) DESC"
                   
  stats[:providers] = ActiveRecord::Base.connection.select_all(providers_sql)
  
  return stats
end


report_stats