#!/usr/bin/env ruby

# This loads up the pseudo synonyms currently used in Solr and cleans them up
# (ie: removes the underscored versions) so that someone like Franck can update them easily.
#
# This script will output the cleaned up version of the synonyms to STDIN.
#
# Example usage: 
#
#  ruby script/biocatalogue/cleanup_pseudo_synonyms_from_solr.rb > cleaned_up_pseudo_synonyms.txt

require File.join(File.dirname(__FILE__), 'shared', 'pseudo_synonyms')

include PseudoSynonyms

filename = File.join(File.dirname(__FILE__), '..', '..', 'vendor', 'plugins', 'acts_as_solr', 'solr', 'solr', 'conf', 'synonyms.txt')

synonynms_in = IO.read(filename)

found = false

synonynms_in.split(/[\n]/).map{|i| i.strip}.each do |line|
  
  found = true if !found and line.match("# BEGIN BioCatalogue")
  
  if found
    
    if line.nil? or line == "\n" or line.strip == "" or line[0,1] == "#"
      puts line
    else
      
      lhs, rhs = line.split("=>")
      
      lhs = lhs.split(',').compact.map{|i| i.strip}.reject{|i| i == "" or i.include?('_')}
      rhs = rhs.split(',').compact.map{|i| i.strip}.reject{|i| i == "" or i.include?('_')}
      
      puts "#{to_list(lhs)} => #{to_list(rhs)}"
    end
    
  end
  
end
