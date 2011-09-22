# BioCatalogue: lib/bio_catalogue/filtering/rest_methods.rb
#
# Copyright (c) 2010-2011, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# Module for filtering specific to services

module BioCatalogue
  module Filtering
    module RestMethods
      
      
      # ======================
      # Filter options finders
      # ----------------------
  
      def self.get_filters_for_filter_type(filter_type, limit=nil, search_query=nil)
        case filter_type
          when :tag
            get_filters_for_all_tags(limit, search_query)
          when :tag_rms
            get_filters_for_rest_method_tags(limit, search_query)
          when :tag_ins
            get_filters_for_rest_input_tags(limit, search_query)
          when :tag_outs
            get_filters_for_rest_output_tags(limit, search_query)
          else
            [ ]
        end
      end
      
      # Gets an ordered list of all the tags on everything.
      #
      # Example return data:
      # [ { "id" => "blast", "name" => "blast", "count" => "500" }, { "id" => "bio", "name" => "bio", "count" => "110" }  ... ]
      def self.get_filters_for_all_tags(limit=nil, search_query=nil)
        get_filters_for_tags_by_service_models([ "RestMethod", "RestRepresentation", "RestParameter" ], limit, :all, search_query)
      end
      
      # Gets an ordered list of all the tags on RestMethods.
      #
      # Example return data:
      # [ { "id" => "blast", "name" => "blast", "count" => "500" }, { "id" => "bio", "name" => "bio", "count" => "110" }  ... ]
      def self.get_filters_for_rest_method_tags(limit=nil, search_query=nil)
        get_filters_for_tags_by_service_models([ "RestMethod" ], limit, nil, search_query)
      end
      
      # Gets an ordered list of all the tags on rest inputs i.e. request_parameters and request_representations.
      #
      # Example return data:
      # [ { "id" => "blast", "name" => "blast", "count" => "500" }, { "id" => "bio", "name" => "bio", "count" => "110" }  ... ]
      def self.get_filters_for_rest_input_tags(limit=nil, search_query=nil)
        get_filters_for_tags_by_service_models([ "RestRepresentation", "RestParameter" ], limit, :request, search_query)
      end
      
      # Gets an ordered list of all the tags on rest outputs i.e. response_parameters, response_representations
      #
      # Example return data:
      # [ { "id" => "blast", "name" => "blast", "count" => "500" }, { "id" => "bio", "name" => "bio", "count" => "110" }  ... ]
      def self.get_filters_for_rest_output_tags(limit=nil, search_query=nil)
        get_filters_for_tags_by_service_models([ "RestRepresentation", "RestParameter" ], limit, :response, search_query)
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
        
        rest_method_ids_for_tag_filters = { }
        
        unless filters.blank?
          filters.each do |filter_type, filter_values|
            unless filter_values.blank?
              case filter_type
                when :tag
                  rest_method_ids_for_tag_filters[filter_type] = get_rest_method_ids_with_tag_on_models([ "RestMethod", "RestRepresentation", "RestParameter" ], filter_values, :all)
                when :tag_rms
                  rest_method_ids_for_tag_filters[filter_type] = get_rest_method_ids_with_tag_on_models([ "RestMethod" ], filter_values)
                when :tag_ins
                  rest_method_ids_for_tag_filters[filter_type] = get_rest_method_ids_with_tag_on_models([ "RestRepresentation", "RestParameter" ], filter_values, :request)
                when :tag_outs
                  rest_method_ids_for_tag_filters[filter_type] = get_rest_method_ids_with_tag_on_models([ "RestRepresentation", "RestParameter" ], filter_values, :response)
              end
            end
          end
        end
        
#        rest_method_ids_for_tag_filters.each do |k,v| 
#          Util.say "*** rest_method_ids found for tags filter '#{k.to_s}' = #{v.inspect}" 
#        end
        
        rest_method_ids_search_query = [ ]
        
        # Take into account search query if present
        unless search_query.blank?
          search_results = Search.search(search_query, "rest_methods")
          unless search_results.blank?
            rest_method_ids_search_query = search_results.item_ids_for("rest_methods")
          end
#          Util.say "*** rest_method_ids_search_query = #{rest_method_ids_search_query.inspect}" 
        end
        
        # Need to go through the various rest method IDs found for the different criterion 
        # and add to the conditions collection (if common ones are found).
        
        # The logic is as follows:
        # - The IDs found between the *different* tag filters should be AND'ed
        # - Results from the above + results from search will be AND'ed
        
        # This will hold...
        # [ [ IDs from search ], [ IDs from tag filter xx ], [ IDs from tag filter yy ], ... ]
        rest_method_id_arrays_to_process = [ ]
        rest_method_id_arrays_to_process << rest_method_ids_search_query.uniq unless search_query.blank?
        rest_method_id_arrays_to_process.concat(rest_method_ids_for_tag_filters.values)
               
        # To carry out this process properly, we set a dummy value of 0 to any array where relevant filters were specified but no matches were found.
        rest_method_id_arrays_to_process.each do |x|
          x = [ 0 ] if x.blank?
        end
        
        # Now work out final combination of IDs 
        
        final_rest_method_ids = nil
        
        rest_method_id_arrays_to_process.each do |a|
          if final_rest_method_ids.nil?
            final_rest_method_ids = a
          else
            final_rest_method_ids = (final_rest_method_ids & a)
          end
        end
        
#        Util.say "*** final_rest_method_ids (after combining all rest methods IDs found) = #{final_rest_method_ids.inspect}"
        
        unless final_rest_method_ids.nil?
          # Remove the dummy value of 0 in case it is in there
          final_rest_method_ids.delete(0)
          
          # If filter(s) / query were specified but nothing was found that means we have an empty result set
          final_rest_method_ids = [ -1 ] if final_rest_method_ids.blank? and 
                                               (!rest_method_ids_for_tag_filters.keys.blank? or !search_query.blank?)
          
#          Util.say "*** final_rest_method_ids (after cleanup) = #{final_rest_method_ids.inspect}"
          
          conditions[:id] = final_rest_method_ids unless final_rest_method_ids.blank?
        end
        
        return [ conditions, joins ]
      end
      
      
    protected
      
      
      # Gets an ordered list of all the tags on a particular set of models 
      # (should be restricted to "RestMethod", "RestParameter" and "RestRepresentation").
      # The counts that are returned reflect the number of rest methods that match 
      # (taking into account mapping of rest inputs and rest outputs to rest methods).
      # 
      # Example return data:
      # [ { "id" => "bio", "name" => "blast", "count" => "500" }, { "id" => "bio", "name" => "bio", "count" => "110" }  ... ]
      def self.get_filters_for_tags_by_service_models(model_names, limit=nil, http_cycle=nil, search_query=nil)
        sql = [ 
          "SELECT tags.name AS name, annotations.annotatable_id AS id, annotations.annotatable_type AS type
          FROM annotations 
          INNER JOIN annotation_attributes ON annotations.attribute_id = annotation_attributes.id
          INNER JOIN tags ON tags.id = annotations.value_id AND annotations.value_type = 'Tag'
          WHERE annotation_attributes.name = 'tag' AND annotations.annotatable_type IN (?)",
          model_names 
        ]
        
        # If limit has been provided in the URL then add that to query.
        #
        # FIXME: limit specified here isn't actually the limit on how many
        # filters are returned. Rather, the amount of data fetched from the 
        # db to process.
        if !limit.nil? && limit.is_a?(Fixnum) && limit > 0
          sql[0] = sql[0] + " LIMIT #{limit}"
        end
        
        items = ActiveRecord::Base.connection.select_all(ActiveRecord::Base.send(:sanitize_sql, sql))
        
        # Group these tags and find out how many services match.
        # NOTE: MUST take into account that multiple service substructure objects could belong to the same RestMethod, AND
        # take into account tags with different case (must treat them in a case-insensitive way).
        
        grouped_tags = { }
        
        items.each do |item|
          next unless BioCatalogue::Util.validate_as_rest_input_output_else_true(item, http_cycle)
                    
          # FIND TAGS
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
        
        search_rest_method_ids = [ ]
        
        # Take into account search query if present
        unless search_query.blank?
          search_results = Search.search(search_query, "rest_methods")
          unless search_results.blank?
            search_rest_method_ids = search_results.item_ids_for("rest_methods")
          end
        end
        
        filters = [ ]
        
        grouped_tags.each do |tag_name, ids|
          rest_method_ids = BioCatalogue::Mapper.process_compound_ids_to_associated_model_object_ids(ids, "RestMethod")
          
          rest_method_ids = rest_method_ids.compact.uniq
          
          # Take into account search before adding a filter to the list
          overlap_rest_method_ids = (search_rest_method_ids & rest_method_ids)
          if search_query.blank? || !overlap_rest_method_ids.empty?
            filters << { 
              'id' => tag_name, 
              'name' => BioCatalogue::Tags.split_ontology_term_uri(tag_name).last,
              'count' => search_query.blank? ? rest_method_ids.length.to_s : overlap_rest_method_ids.length.to_s 
            }
          end
        end
        
        filters.sort! { |a,b| b['count'].to_i <=> a['count'].to_i }
        
        return filters
      end
      
      def self.get_rest_method_ids_with_tag_on_models(model_names, tag_values, http_cycle=nil)
        # NOTE: this query has only been tested to work with MySQL 5.0.x
        sql = [ 
          "SELECT annotations.annotatable_id AS id, annotations.annotatable_type AS type
          FROM annotations 
          INNER JOIN annotation_attributes ON annotations.attribute_id = annotation_attributes.id
          INNER JOIN tags ON tags.id = annotations.value_id AND annotations.value_type = 'Tag'
          WHERE annotation_attributes.name = 'tag' AND annotations.annotatable_type IN (?) AND tags.name IN (?)",
          model_names,
          tag_values 
        ]
        
        results = ActiveRecord::Base.connection.select_all(ActiveRecord::Base.send(:sanitize_sql, sql))
        results.reject! { |item| !BioCatalogue::Util.validate_as_rest_input_output_else_true(item, http_cycle) }        
                
        return BioCatalogue::Mapper.process_compound_ids_to_associated_model_object_ids(results.map{|r| BioCatalogue::Mapper.compound_id_for(r['type'], r['id']) }, "RestMethod").uniq     
      end
            
    end
  end
end