#!/usr/bin/env ruby

# This script loads up some synonyms (in the Solr/Lucene synonyms format) and does some processing on it.
# It then outputs the final list of synonyms that should be used, to the console.
#
# You need to provide a path (relative to the directory you call this script in) to a file that contains raw synonym data, as a command line parameter. 
#
# 
# Main usage: 
#
#  ruby script/biocatalogue/process_pseudo_synonyms_for_solr.rb "../../data/ontology_synonyms_raw.txt"

require File.join(File.dirname(__FILE__), 'shared', 'pseudo_synonyms')

include PseudoSynonyms

synonynms_in = ""
synonyms_out = { }

if ARGV.empty?
  puts "You need to provide the relative path to a file that contains raw synonym data to be processed!"
else
  
  filename = ARGV[0]
  
  puts "Loading synonyms data from #{filename}"
     
  synonynms_in = IO.read(filename)
     
  if synonynms_in.nil? or synonynms_in == ''
    puts ""
    puts "No synonyms to process. Exiting...."
  else
    
    puts "Processing the following raw synonyms data: "
    puts "-------------------------------------------"
    puts synonynms_in
    
    puts ""
    puts "Processing now..."
    puts ""
    
    synonynms_in.split(/[\n]+/).compact.map{|i| i.strip}.reject{|i| i == ""}.each do |line|
      
      lhs_in, rhs_in = line.split("=>")
      
      lhs_in = lhs_in.split(',').compact.map{|i| i.strip}.reject{|i| i == ""}
      rhs_in = rhs_in.split(',').compact.map{|i| i.strip}.reject{|i| i == ""}
      
      rhs_in.each do |term|
        unless array_includes?(lhs_in, term)
          lhs_out = underscored_and_spaced_versions_of(process_values(term)).uniq
          rhs_out = underscored_and_spaced_versions_of(process_values(term, lhs_in)).uniq  
          
          if synonyms_out.has_key?(lhs_out)
            puts "WARNING: found more synonyms for existing key: #{lhs_out.inspect}. Merging the two collections. POSSIBLE DISAMBIGUATION!!!"
            synonyms_out[lhs_out] = (synonyms_out[lhs_out] + rhs_out).uniq
          else
            synonyms_out[lhs_out] = rhs_out
          end
        end        
      end
      
    end
    
    puts ""
    puts "Synonyms for SOLR:"
    puts "=================="
    puts ""
    
    output_synonyms(synonyms_out)
     
  end
   
 end