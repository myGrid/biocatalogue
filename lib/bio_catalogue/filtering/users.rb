# BioCatalogue: lib/bio_catalogue/filtering/users.rb
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# Module for filtering specific to users

module BioCatalogue
  module Filtering
    module Users
      
      # ======================
      # Filter options finders
      # ----------------------
  
      def self.get_filters_for_filter_type(filter_type, limit=nil)
        case filter_type
          when :c
            get_filters_for_countries(limit)
          else
            [ ]
        end
      end
      
            
      # Gets an ordered list of all the countries (the users are in) and their counts.
      #
      # Example return data:
      # [ { "id" => England", "name" => "England", "count" => "18" }, { "id" => "Germany", "name" => "Germany", "count" => "5" }, { "id" => "(unknown), "name" => "(unknown)", "count" => "3" }  ... ]
      def self.get_filters_for_countries(limit=nil)
        # NOTE: this query has only been tested to work with MySQL 5.0.x
        sql = "SELECT users.country AS id, users.country AS name, COUNT(*) AS count 
              FROM users
              GROUP BY users.country
              ORDER BY COUNT(*) DESC"
        
        # If limit has been provided in the URL then add that to query.
        if !limit.nil? && limit.is_a?(Fixnum) && limit > 0
          sql += " LIMIT #{limit}"
        end
         
        items = ActiveRecord::Base.connection.select_all(sql)

        return_items = []
        unknown_country_item = nil
        
        # Need to replace the blank name with "(unknown)" (for users that don't have a country set)
        items.each do |item|
          if unknown_country_item && item['name'].blank?
            unknown_country_item['count'] = unknown_country_item['count'].to_i + item['count'].to_i
            item = nil
          elsif item['name'].blank?
            item['name'] = UNKNOWN_TEXT
            item['id'] = UNKNOWN_TEXT
            unknown_country_item = item
            return_items << unknown_country_item
          else
            return_items << item
          end
        end
        
        return return_items
      end

      
      # ======================
      
      
      # Returns:
      #   [ conditions, joins ] for use in an ActiveRecord .find method (or .paginate).
      def self.generate_conditions_and_joins_from_filters(filters, search_query=nil)
        conditions = { }
        joins = [ ]
        
        return [ conditions, joins ] if filters.blank? && search_query.blank?
        
        # Replace the unknown filter with nil
        filters.each do |k,v|
          v.each do |f|
            if f == UNKNOWN_TEXT
              v << nil
              v.delete(f)
            end
          end
        end
              
        # Now build the conditions and joins...
        
        user_ids_search_query = [ ]
        
        unless filters.blank?
          filters.each do |filter_type, filter_values|
            unless filter_values.blank?
              case filter_type
                when :c
                  countries = filter_values
                  conditions[:country] = countries unless countries.blank?
              end
            end
          end
        end
        
        # Take into account search query if present
        unless search_query.blank?
          search_results = Search.search(search_query, "users")
          unless search_results.blank?
            user_ids_search_query = search_results.item_ids_for("users")
          end
        end

        # Need to go through the various user IDs found for the different criterion 
        # and add to the conditions collection (if common ones are found).
        # This ANDs the user IDs (ie: uses only the user IDs that match all criterion).
        
        # To carry out this process properly, we set a dummy value of 0 to any array that returned NO user IDs.
        user_ids_search_query = [ 0 ] if user_ids_search_query.empty? and !search_query.blank?
        
#        Util.say "*** user_ids_search_query = #{user_ids_search_query.inspect}"
        
        user_id_arrays_to_process = [ ]
        user_id_arrays_to_process << user_ids_search_query unless search_query.blank?
        
        final_user_ids = nil
        
        user_id_arrays_to_process.each do |a|
          if final_user_ids.nil?
            final_user_ids = a
          else
            final_user_ids = (final_user_ids & a)
          end
        end
        
#        Util.say "*** final_user_ids (after combining user id arrays) = #{final_user_ids.inspect}"
        
        unless final_user_ids.nil?
          # Remove the dummy value of 0 in case it is in there
          final_user_ids.delete(0)
          
          # If filter(s) / query were specified but nothing was found that means we have an empty result set
          final_user_ids = [ -1 ] if final_user_ids.blank? and !search_query.blank?
          
#          Util.say "*** final_user_ids (after cleanup) = #{final_user_ids.inspect}"
          
          conditions[:id] = final_user_ids unless final_user_ids.blank?
        end
        
        return [ conditions, joins ]
      end
    
    end
  end
end