# BioCatalogue: lib/bio_catalogue/bljson.rb
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# Module to abstract out any specific processing for the custom BioCatalogue "lean" JSON REST API

module BioCatalogue
  module Api
    module Bljson
      
      def self.index(resource_type, results, params={})
        output = Hash.new { |h,k| h[k] = [ ] }
        
        results.each do |item|
          item_json = { :resource => BioCatalogue::Api.uri_for_object(item), :name => BioCatalogue::Util.display_name(item) }
          output[resource_type.pluralize] << item_json
        end
        
        return output
      end
      
    end
  end
end