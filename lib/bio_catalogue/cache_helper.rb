# BioCatalogue: lib/bio_catalogue/cache_helper.rb
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# Helper module to provide functions to aid in caching.

module BioCatalogue
  module CacheHelper
    
    NO_VALUE = "<none>".freeze
    
    def self.cache_key_for(type, *args)
      case type
        when :metadata_counts_for_service
          "metadata_counts_for_service_#{args[0].id}"
      end
    end
    
    module Expires
      
      def expire_service_index_tag_cloud
        expire_fragment(:controller => 'services', :action => 'index', :action_suffix => 'tag_cloud')
      end
      
    end
    
  end
end