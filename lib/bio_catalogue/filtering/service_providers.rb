# BioCatalogue: lib/bio_catalogue/filtering/service_providers.rb
#
# Copyright (c) 2010-2011, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# Module for filtering specific to service_providers

module BioCatalogue
  module Filtering
    module ServiceProviders
      
      # ======================
      # Filter options finders
      # ----------------------
  
      def self.get_filters_for_filter_type(filter_type, limit=nil, search_query=nil)
        [ ]
      end
      
            
      # ======================
      
      
      # Returns:
      #   [ conditions, joins ] for use in an ActiveRecord .find method (or .paginate).
      # ONLY USES search_query
      def self.generate_conditions_and_joins_from_filters(filters, search_query=nil)
        conditions = { }
        joins = [ ]
        
        return [ conditions, joins ] if search_query.blank?
                              
        # Now build the conditions and joins...
        
        service_provider_ids_search_query = [ ]
        
        # Use search query if present
        unless search_query.blank?
          search_results = Search.sunspot_search(search_query, "service_providers")
          unless search_results.blank?
            #service_provider_ids_search_query = search_results.item_ids_for("service_providers")
            service_provider_ids_search_query = BioCatalogue::Search::Results::get_item_ids(search_results, 'service_providers')
          end
        end

        # Need to go through the various service_provider IDs found for the different criterion 
        # and add to the conditions collection (if common ones are found).
        # This ANDs the service_provider IDs (ie: uses only the service_provider IDs that match all criterion).
        
        # To carry out this process properly, we set a dummy value of 0 to any array that returned NO service_provider IDs.
        service_provider_ids_search_query = [ 0 ] if service_provider_ids_search_query.empty? and !search_query.blank?
        
#        Util.say "*** service_provider_ids_search_query = #{service_provider_ids_search_query.inspect}"
        
        service_provider_id_arrays_to_process = [ ]
        service_provider_id_arrays_to_process << service_provider_ids_search_query unless search_query.blank?
        
        final_service_provider_ids = nil
        
        service_provider_id_arrays_to_process.each do |a|
          if final_service_provider_ids.nil?
            final_service_provider_ids = a
          else
            final_service_provider_ids = (final_service_provider_ids & a)
          end
        end
        
#        Util.say "*** final_service_provider_ids (after combining service_provider id arrays) = #{final_service_provider_ids.inspect}"
        
        unless final_service_provider_ids.nil?
          # Remove the dummy value of 0 in case it is in there
          final_service_provider_ids.delete(0)
          
          # If filter(s) / query were specified but nothing was found that means we have an empty result set
          final_service_provider_ids = [ -1 ] if final_service_provider_ids.blank? and !search_query.blank?
          
#          Util.say "*** final_service_provider_ids (after cleanup) = #{final_service_provider_ids.inspect}"
          
          conditions[:id] = final_service_provider_ids unless final_service_provider_ids.blank?
        end
        
        return [ conditions, joins ]
      end
    
    end
  end
end