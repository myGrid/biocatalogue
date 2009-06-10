#!/usr/bin/env ruby

# This script loads up some synonyms (in the Solr/Lucene synonyms format) and does some processing on it.
# It then outputs the final list of synonyms that should be used, to the console.
#
# You need to provide a relative path (relative to this script) to a file that contains raw synonym data, as a command line parameter. 
#
# 
# Main usage: 
#
#  ruby script/biocatalogue/process_pseudo_synonyms_for_solr.rb "../../data/ontology_synonyms_raw.txt"

require File.join(File.dirname(__FILE__), 'shared', 'pseudo_synonyms')

include PseudoSynonyms

synonynms = ""

if ARGV.empty?
  puts "You need to provide the relative path to a file that contains raw synonym data to be processed!"
else
  
  filename = ARGV[0]
  
  full_filename = File.expand_path(File.join(File.dirname(__FILE__), filename))
  puts "Loading synonyms data from #{full_filename}"
     
  synonyms = IO.read(full_filename)
     
  if synonyms.nil? or synonyms == ''
    puts ""
    puts "No synonyms to process. Exiting...."
  else
    
    puts "Processing the following raw synonyms data: "
    puts synonyms
    
    puts ""
    puts ""
    puts "Synonyms for SOLR:"
    puts "=================="
    puts ""
     
    synonyms.split(/[\n]+/).compact.reject{|i| i.strip == ""}.each do |line|
      
      lhs_raw, rhs_raw = line.split("=>")
      
      lhs = process_values(underscored_and_spaced_versions_of(process_values(lhs_raw.split(',').compact.reject{|i| i == ""}.map{|i| i.strip})))
      rhs = process_values(underscored_and_spaced_versions_of(process_values(rhs_raw.split(',').compact.reject{|i| i == ""}.map{|i| i.strip})))
      
      puts "#{to_list(lhs)} => #{to_list(rhs)}"
      
    end
     
  end
   
 end