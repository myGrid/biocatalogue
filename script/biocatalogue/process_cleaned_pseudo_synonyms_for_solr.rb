#!/usr/bin/env ruby

# This script loads up a list of cleaned up synoyms (in the Solr/Lucene synonyms format) and add underscored words.
# It then outputs the final list of synonyms that should be used, to the console.
#
# You need to provide a path (relative to the directory you call this script in) to a file that contains the cleaned up synonym data, as a command line parameter. 
#
# 
# Main usage: 
#
#  ruby script/biocatalogue/process_cleaned_pseudo_synonyms_for_solr.rb "cleaned_pseudo_synoyms.txt"

require File.join(File.dirname(__FILE__), 'shared', 'pseudo_synonyms')

include PseudoSynonyms

synonynms_in = ""
synonyms_out = { }

if ARGV.empty?
  puts "You need to provide the relative path to a file that contains cleaned synonym data to be processed!"
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
    
    puts "Synonyms for SOLR:"
    puts "=================="
    puts ""
    
    synonynms_in.split(/[\n]/).map{|i| i.strip}.each do |line|
      
      if line.nil? or line == "\n" or line.strip == "" or line[0,1] == "#"
        puts line
      else
      
        lhs_in, rhs_in = line.split("=>")
        
        lhs_in = lhs_in.split(',').compact.map{|i| i.strip}.reject{|i| i == ""}
        rhs_in = rhs_in.split(',').compact.map{|i| i.strip}.reject{|i| i == ""}
        
        lhs_out = underscored_and_spaced_versions_of(process_values(lhs_in))
        rhs_out = underscored_and_spaced_versions_of(process_values(rhs_in)) 
        
        puts "#{to_list(lhs_out)} => #{to_list(rhs_out)}"
        
      end
      
    end
    
  end
   
 end