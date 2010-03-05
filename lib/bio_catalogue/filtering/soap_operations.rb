# BioCatalogue: lib/bio_catalogue/filtering/soap_operations.rb
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# Module for filtering specific to services

module BioCatalogue
  module Filtering
    module SoapOperations
      
      
      # ======================
      # Filter options finders
      # ----------------------
  
      def self.get_filters_for_filter_type(filter_type, limit=nil)
        case filter_type
          when :tag
            get_filters_for_all_tags(limit)
          when :tag_ops
            get_filters_for_soap_operation_tags(limit)
          when :tag_ins
            get_filters_for_soap_input_tags(limit)
          when :tag_outs
            get_filters_for_soap_output_tags(limit)
          else
            [ ]
        end
      end
      
      # Gets an ordered list of all the tags on everything.
      #
      # Example return data:
      # [ { "id" => "blast", "name" => "blast", "count" => "500" }, { "id" => "bio", "name" => "bio", "count" => "110" }  ... ]
      def self.get_filters_for_all_tags(limit=nil)
        get_filters_for_tags_by_service_models([ "SoapOperation", "SoapInput", "SoapOutput" ], limit)
      end
      
      # Gets an ordered list of all the tags on SoapOperations.
      #
      # Example return data:
      # [ { "id" => "blast", "name" => "blast", "count" => "500" }, { "id" => "bio", "name" => "bio", "count" => "110" }  ... ]
      def self.get_filters_for_soap_operation_tags(limit=nil)
        get_filters_for_tags_by_service_models([ "SoapOperation" ], limit)
      end
      
      # Gets an ordered list of all the tags on SoapInputs.
      #
      # Example return data:
      # [ { "id" => "blast", "name" => "blast", "count" => "500" }, { "id" => "bio", "name" => "bio", "count" => "110" }  ... ]
      def self.get_filters_for_soap_input_tags(limit=nil)
        get_filters_for_tags_by_service_models([ "SoapInput" ], limit)
      end
      
      # Gets an ordered list of all the tags on SoapOutputs.
      #
      # Example return data:
      # [ { "id" => "blast", "name" => "blast", "count" => "500" }, { "id" => "bio", "name" => "bio", "count" => "110" }  ... ]
      def self.get_filters_for_soap_output_tags(limit=nil)
        get_filters_for_tags_by_service_models([ "SoapOutput" ], limit)
      end
      
      # ======================
      
      # Returns:
      #   [ conditions, joins ] for use in an ActiveRecord .find method (or .paginate).
      # TODO: implement use of the search_query, so you can search within SoapOperations too!
      def self.generate_conditions_and_joins_from_filters(filters, search_query=nil)
        conditions = { }
        joins = [ ]
        
        return [ conditions, joins ] if filters.blank?
        
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
        
        soap_operation_ids_for_tag_filters = { }
        
        unless filters.blank?
          filters.each do |filter_type, filter_values|
            unless filter_values.blank?
              case filter_type
                when :tag
                  soap_operation_ids_for_tag_filters[filter_type] = get_soap_operation_ids_with_tag_on_models([ "SoapOperation", "SoapInput", "SoapOutput" ], filter_values)
                when :tag_ops
                  soap_operation_ids_for_tag_filters[filter_type] = get_soap_operation_ids_with_tag_on_models([ "SoapOperation" ], filter_values)
                when :tag_ins
                  soap_operation_ids_for_tag_filters[filter_type] = get_soap_operation_ids_with_tag_on_models([ "SoapInput" ], filter_values)
                when :tag_outs
                  soap_operation_ids_for_tag_filters[filter_type] = get_soap_operation_ids_with_tag_on_models([ "SoapOutput" ], filter_values)
              end
            end
          end
        end
        
        soap_operation_ids_for_tag_filters.each do |k,v| 
          Util.say "*** soap_operation_ids found for tags filter '#{k.to_s}' = #{v.inspect}" 
        end
        
        soap_operation_ids_search_query = [ ]
        
        # Take into account search query if present
        unless search_query.blank?
          search_results = Search.search(search_query, "soap_operations")
          unless search_results.blank?
            soap_operation_ids_search_query = search_results.item_ids_for("soap_operations")
          end
          Util.say "*** soap_operation_ids_search_query = #{soap_operation_ids_search_query.inspect}" 
        end
        
        # Need to go through the various soap operation IDs found for the different criterion 
        # and add to the conditions collection (if common ones are found).
        
        # The logic is as follows:
        # - The IDs found between the *different* tag filters should be AND'ed
        # - Results from the above + results from search will be AND'ed
        
        # This will hold...
        # [ [ IDs from search ], [ IDs from tag filter xx ], [ IDs from tag filter yy ], ... ]
        soap_operation_id_arrays_to_process = [ ]
        soap_operation_id_arrays_to_process << soap_operation_ids_search_query.uniq unless search_query.blank?
        soap_operation_id_arrays_to_process.concat(soap_operation_ids_for_tag_filters.values)
               
        # To carry out this process properly, we set a dummy value of 0 to any array where relevant filters were specified but no matches were found.
        soap_operation_id_arrays_to_process.each do |x|
          x = [ 0 ] if x.blank?
        end
        
        # Now work out final combination of IDs 
        
        final_soap_operation_ids = nil
        
        soap_operation_id_arrays_to_process.each do |a|
          if final_soap_operation_ids.nil?
            final_soap_operation_ids = a
          else
            final_soap_operation_ids = (final_soap_operation_ids & a)
          end
        end
        
        Util.say "*** final_soap_operation_ids (after combining all soap operations IDs found) = #{final_soap_operation_ids.inspect}"
        
        unless final_soap_operation_ids.nil?
          # Remove the dummy value of 0 in case it is in there
          final_soap_operation_ids.delete(0)
          
          # If filter(s) / query were specified but nothing was found that means we have an empty result set
          final_soap_operation_ids = [ -1 ] if final_soap_operation_ids.blank? and 
                                               (!soap_operation_ids_for_tag_filters.keys.blank? or !search_query.blank?)
          
          Util.say "*** final_soap_operation_ids (after cleanup) = #{final_soap_operation_ids.inspect}"
          
          conditions[:id] = final_soap_operation_ids unless final_soap_operation_ids.blank?
        end
        
        return [ conditions, joins ]
      end
      
      
      protected
      
      
      # Gets an ordered list of all the tags on a particular set of models 
      # (should be restricted to "SoapOperation", "SoapInput" and "SoapOutput").
      # The counts that are returned reflect the number of soap operations that match 
      # (taking into account mapping of soap inputs and soap outputs to soap operations).
      # 
      # Example return data:
      # [ { "id" => "bio", "name" => "blast", "count" => "500" }, { "id" => "bio", "name" => "bio", "count" => "110" }  ... ]
      def self.get_filters_for_tags_by_service_models(model_names, limit=nil)
        # NOTE: this query has only been tested to work with MySQL 5.0.x
        sql = [ "SELECT annotations.value AS name, annotations.annotatable_id AS id, annotations.annotatable_type AS type
                FROM annotations 
                INNER JOIN annotation_attributes ON annotations.attribute_id = annotation_attributes.id
                WHERE annotation_attributes.name = 'tag' AND annotations.annotatable_type IN (?)",
                model_names ]
        
        # If limit has been provided in the URL then add that to query.
        # TODO: this is buggy!
        if !limit.nil? && limit.is_a?(Fixnum) && limit > 0
          sql[0] = sql[0] + " LIMIT #{limit}"
        end
        
        items = ActiveRecord::Base.connection.select_all(ActiveRecord::Base.send(:sanitize_sql, sql))
        
        # Group these tags and find out how many services match.
        # NOTE: MUST take into account that multiple service substructure objects could belong to the same Service, AND
        # take into account tags with different case (must treat them in a case-insensitive way).
        
        grouped_tags = { }
        
        items.each do |item|
          found = false
          
          tag_name = item['name']
          
          grouped_tags.each do |k,v|
            if k.downcase == tag_name.downcase
              found = true
              grouped_tags[k] << BioCatalogue::Mapper.compound_id_for(item['type'], item['id'])
            end
          end
          
          unless found
            grouped_tags[tag_name] = [ ] if grouped_tags[tag_name].nil?
            grouped_tags[tag_name] << BioCatalogue::Mapper.compound_id_for(item['type'], item['id'])
          end
            
        end
        
        filters = [ ]
        
        grouped_tags.each do |tag_name, ids|
          soap_operation_ids = BioCatalogue::Mapper.process_compound_ids_to_associated_model_object_ids(ids, "SoapOperation")
          soap_operation_ids = soap_operation_ids.compact.uniq
          filters << { 'id' => tag_name, 'name' => tag_name, 'count' => soap_operation_ids.length.to_s }
        end
        
        filters.sort! { |a,b| b['count'].to_i <=> a['count'].to_i }
        
        return filters
      end
      
      def self.get_soap_operation_ids_with_tag_on_models(model_names, tag_values)
        # NOTE: this query has only been tested to work with MySQL 5.0.x
        sql = [ "SELECT annotations.annotatable_id AS id, annotations.annotatable_type AS type
                FROM annotations 
                INNER JOIN annotation_attributes ON annotations.attribute_id = annotation_attributes.id
                WHERE annotation_attributes.name = 'tag' AND annotations.annotatable_type IN (?) AND annotations.value IN (?)",
                model_names,
                tag_values ]
        
        results = ActiveRecord::Base.connection.select_all(ActiveRecord::Base.send(:sanitize_sql, sql))
        
        return BioCatalogue::Mapper.process_compound_ids_to_associated_model_object_ids(results.map{|r| BioCatalogue::Mapper.compound_id_for(r['type'], r['id']) }, "SoapOperation").uniq     
      end
      
    end
  end
end