#!/usr/bin/env ruby

# BioCatalogue: script/biocatalogue/update_country_names_dec12.rb
#
# Copyright (c) 2012, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# Updates the country names for services to the Titlecase version.

env = "production"

unless ARGV[0].nil? or ARGV[0] == ''
  env = ARGV[0]
end

RAILS_ENV = env

# Load up the Rails app
require File.join(File.dirname(__FILE__), '..', '..', 'config', 'environment')

count = 0

begin

  ServiceDeployment.record_timestamps = false

  ServiceDeployment.transaction do 
    ServiceDeployment.find(:all, :conditions =>["country IS NOT ?", nil]).each do |sd|
      new_country = case sd.country
      when "CÔTE D'IVOIRE"
        "Côte d'Ivoire"
      when "SAINT BARTHÉLEMY"
        "Saint Barthélemy"
      when "SAINT MARTIN (FRENCH PART)"
        "Saint Martin (French part)"
      when "GUINEA-BISSAU"
        "Guinea-Bissau"
      when "TIMOR-LESTE"
        "Timor-Leste"
      else
        sd.country.titlecase
      end

      ["And", "The", "Of"].each do |w|
        new_country.gsub!(w, w.downcase)
      end

      sd.country = new_country
      sd.save!
      count += 1
    end
  end

  ServiceDeployment.record_timestamps = true

rescue Exception => ex
  puts ""
  puts "> ERROR: exception occured and transaction has been rolled back. Exception:"
  puts ex.message
  puts ex.backtrace.join("\n")
end

puts "> #{count} service deployment countries updated"
