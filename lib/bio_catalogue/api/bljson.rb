# BioCatalogue: lib/bio_catalogue/bljson.rb
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# Module to abstract out any specific processing for the custom BioCatalogue "lean" JSON REST API

module BioCatalogue
  module Api
    module Bljson
      
      # 'results' should be a Hash with an "id" + anything that can be deemed a display_name. 
      def self.index(resource_type, results)
        output = { }
        
        output[resource_type.pluralize] = [ ]
        
        results.each do |item|
          puts "\n**\n#{item.inspect}\n**\n"
          item_json = { :resource => BioCatalogue::Api.uri_for_path("/#{resource_type}/#{item["id"]}"), :name => BioCatalogue::Util.display_name(item) }
          output[resource_type.pluralize] << item_json
        end
        
        return output
      end
      
    end
  end
end