#!/usr/bin/env ruby

# This loads up the service categories and outputs to the console a list of synonyms for use in Solr.

require 'yaml'
require 'pp'

require File.join(File.dirname(__FILE__), 'shared', 'pseudo_synonyms')

include PseudoSynonyms

categories = YAML.load(IO.read(File.join(File.dirname(__FILE__), '..', '..', 'data', 'service_categories.yml')))

puts "Processing the following raw categories data: "
pp categories

puts ""
puts ""
puts "Synonyms for SOLR:"
puts "=================="
puts ""

def process_node(node)
  node.each do |key, children|
    unless children.nil?
      case children
        when Array
          lhs = underscored_and_spaced_versions_of(process_values(key)).uniq
          rhs = underscored_and_spaced_versions_of(process_values(key, children)).uniq
          puts "#{to_list(lhs)} => #{to_list(rhs)}"
        when Hash
          process_node(children)
      end
    end
  end
end

process_node(categories)
