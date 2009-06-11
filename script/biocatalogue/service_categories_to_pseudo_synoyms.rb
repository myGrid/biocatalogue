#!/usr/bin/env ruby

# This loads up the service categories and outputs to the console a list of synonyms for use in Solr.

require 'yaml'
require 'pp'

require File.join(File.dirname(__FILE__), 'shared', 'pseudo_synonyms')

include PseudoSynonyms
  
IGNORES = [ "Sequence Analysis" ]

categories = YAML.load(IO.read(File.join(File.dirname(__FILE__), '..', '..', 'data', 'service_categories.yml')))

puts "Processing the following raw categories data: "
pp categories

puts ""
puts ""
puts "Synonyms for SOLR:"
puts "=================="
puts ""

def process_node(node, synonyms_collection)
  node.each do |key, children|
    key = key.split('[')[0].strip
    unless children.nil? or array_includes?(IGNORES, key)
      case children
        when Array
          children = children.map{|c| c.split('[')[0].strip}
          
          children.each do |child|
            lhs = underscored_and_spaced_versions_of(process_values(child)).uniq
            rhs = underscored_and_spaced_versions_of(process_values(child, key)).uniq  
            
            synonyms_collection[lhs] = rhs
          end
          
        when Hash
          process_node(children, synonyms_collection)
      end
    end
  end
end

synonyms = { }

process_node(categories, synonyms)

output_synonyms(synonyms)
