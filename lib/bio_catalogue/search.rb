# BioCatalogue: lib/bio_catalogue/search.rb
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

module BioCatalogue
  module Search
    
    # MUST correspond to pluralised and underscored model names.
    VALID_SEARCH_SCOPES = [ "services", "service_providers", "users", "registries" ].freeze
    
    ALL_SCOPE_SYNONYMS = [ "all", "any" ].freeze
    
    VALID_SEARCH_SCOPES_INCL_ALL = ([ ALL_SCOPE_SYNONYMS[0] ] + VALID_SEARCH_SCOPES).freeze
    
    # As new models are indexed (and therefore need to be searched on) add them here.
    @@models_for_search = (Mapper::SERVICE_STRUCTURE_MODELS + [ ServiceProvider, User, Registry, Annotation ]).freeze
    
    @@search_query_suggestions_file_path = File.join(Rails.root, 'data', 'search_query_suggestions.txt')
    
    @@limit = 10000
    
    def self.on?
      return ENABLE_SEARCH
    end
    
    def self.update_search_query_suggestions_file
      begin
        
        latest_search_queries = ActivityLog.find_all_by_action("search").map{|a| a.data[:query]}.compact.uniq
        
        categories = Category.all.map{|c| c.name}.uniq
        
        unless latest_search_queries.blank? and categories.blank?
          
          current_data = IO.read(@@search_query_suggestions_file_path)
          
          terms = current_data.split(/[\n]/).compact.map{|i| i.strip}
          
          # Add new terms
          terms = terms + latest_search_queries + categories
          
          # Remove unwanted ones
          excludes = [ "*", "[object htmlcollection]", /^[*]/ ]
          excludes.each do |ex|
            terms.reject! do |t|
              case ex
                when String
                  ex == t
                when Regexp
                  t.match(ex)
                else
                  false
              end
            end
          end
          
          # Remove duplicates
          terms.uniq!
          
          # Sort
          terms = terms.sort { |a,b| a.to_s.downcase <=> b.to_s.downcase }
          
          # Write out
          File.open(@@search_query_suggestions_file_path, 'w') do |f|  
            terms.each do |t|
              f.puts t
            end
          end
        
        end
        
      rescue Exception => ex
        msg = "Could not update the search query suggestions text file. Error message: #{ex.message}"
        Rails.logger.error(msg)
        puts(msg)
      end
    end
    
    def self.get_query_suggestions(query_fragment, limit=100)
      return [ ] if query_fragment.blank?
      
      suggestions = [ ]
      
      begin
        
        current_terms = IO.read(@@search_query_suggestions_file_path).split(/[\n]/).compact.map{|i| i.strip}
        
        current_terms.each do |t|
          s = t.downcase
          suggestions << t if s.match(query_fragment)          
        end
        
      rescue Exception => ex
        msg = "Failed to get query suggestions. Error message: #{ex.message}."
        Rails.logger.error(msg)
        puts(msg)
      end
      
      return suggestions.map{|s| { 'name' => s }}
    end
    
    def self.preprocess_query(query)
      # Check if the query was for a URL, in which case wrap it in quotation marks in order to get through the solr query parser.
      if query.starts_with?("http://") or 
         query.starts_with?("https://")
        query = '"' + query
        query = query + '"'
      end
      
      return query
    end
    
    def self.search(query, scope=ALL_SCOPE_SYNONYMS[0])
      scope = scope.downcase
        
      return nil unless VALID_SEARCH_SCOPES_INCL_ALL.include?(scope)
      
      query = self.preprocess_query(query)
      
      search_result_docs = @@models_for_search.first.multi_solr_search(query, 
        :limit => @@limit, 
        :models => @@models_for_search[1...@@models_for_search.length], 
        :results_format => :ids, 
        :incl_all_fields => true).docs
      
      scopes_for_results = if ALL_SCOPE_SYNONYMS.include?(scope)
        VALID_SEARCH_SCOPES
      else
        [ scope ]
      end
      
      return Results.new(search_result_docs, scopes_for_results)
    end
    
    # =======================
    # Class to handle results
    # -----------------------
    
    # Takes care of processing the raw results from the search engine to useful results for the system,
    # taking into account the specified scopes the raw results should be mapped, processed and grouped into.
    #
    # Takes care of things like mapping SoapOperation results to ancestor Services and so on.
    #
    # Note (1): this only deals with the IDs of objects and never fetches any of the objects from the db directly.
    # Note (2): internally this reads, stores and works with the "compound ID" format: "{model_name}:{id}" to disambiguate between different items.
    class Results
      
      attr_reader :total,             # The total number of search results, regardless of scopes. Integer.
                  :result_scopes      # The scopes that the results should be processed and grouped into. Array of Strings, that correspond to the values in BioCatalogue::Search::VALID_SEARCH_SCOPES or a subset of.
      
      # Internal hash to map scopes to model names and vice versa...
      # So if the only scope was "service_deployments" then the hash would look like:
      #   { "service_deployments" => "ServiceDeployment", "ServiceDeployment" => "service_deployments" }
      @internal_scopes_to_and_from_model_names_map = { }
      
      # Internal variables to store original search results...
      @original_search_docs = [ ]     # The original docs from the search engine.
      @original_ids = [ ]             # Array of Strings of compound IDs (eg: [ "Service:101", "ServiceDeployment:45", "User:6", "User:8" ])
      
      # Internal variables to store the overall combined results...
      @overall_results_ids = [ ]      # Array of Strings of compound IDs (eg: [ "Service:101", "User:6", "User:8" ]) representing the fulle, unique, ordered set of search results according to the scopes required.
      
      # Internal variables to store processed and grouped results...
      @grouped_results_ids = { }      # Hash, where keys are the search scopes (that correspond to the values in BioCatalogue::Search::VALID_SEARCH_SCOPES or a subset of) and values are Arrays of IDs of the objects for that scope. 

      # Object initializer
      #
      # search_docs
      #   the raw docs from the search engine (either an empty Array, Array of Integer IDs, or an Array of String IDs in the compound ID format "{model_name}:{id}").
      # 
      # scopes
      #   the search scopes (that correspond to the values in BioCatalogue::Search::VALID_SEARCH_SCOPES or a subset of) that this Results set needs to deal with.
      #
      def initialize(search_docs, scopes)
        @original_search_docs = Marshal.load(Marshal.dump(search_docs))
        
        @result_scopes = scopes
        
        # Set internal hash for scopes to/from model names
        @internal_scopes_to_and_from_model_names_map = { }
        @result_scopes.each do |s|
          @internal_scopes_to_and_from_model_names_map[s] = s.classify
          @internal_scopes_to_and_from_model_names_map[s.classify] = s
        end
        
        if @original_search_docs.first.kind_of?(Integer)
          # If the search docs only contain integers then we know that they are all of one scope. 
          # In which case only one scope should be specified in 'scopes'.
          
          if scopes.length != 1
            raise "Cannot create results for more than one search scope when only given a set of numerical IDs in the search docs. How am I supposed to determine what model these IDs are for huh? Huh, punk?"
          else
            model_name = @result_scopes.first.classify
            @original_ids = @original_search_docs.map { |r| BioCatalogue::Mapper.compound_id_for(model_name, r) }
          end
        elsif @original_search_docs.first.kind_of?(Hash)
          @original_ids = @original_search_docs.map { |r| r["id"] }
        else
          @original_ids = [ ]
        end
        
        @overall_results_ids = [ ]
        @grouped_results_ids = { }
        
        process_original_ids
      end
      
      # Gets the full search results, as a collection of compound IDs.
      def all_item_ids
        @overall_results_ids
      end
      
      # Gets a paged list of full search results, as a collection of compound IDs.
      def paged_all_item_ids(page, num_per_page)
        @overall_results_ids.paginate(:page => page, :per_page => num_per_page) 
      end
      
      # Gets the item IDs for the specified result scope.
      def item_ids_for(result_scope)
        return @grouped_results_ids[result_scope] || [ ]
      end
      
      # Gets the paged item IDs for the specified result scope.
      def paged_item_ids_for(result_scope, page, num_per_page)
        x = item_ids_for(result_scope)
        return x.paginate(:page => page, :per_page => num_per_page) 
      end
      
      # Gets the count of items for a specified result scope. 
      # If the result scope is invalid then 0 is returned. 
      def count_for(result_scope)
        return @grouped_results_ids[result_scope].try(:length) || 0
      end
      
      protected
      
      # This method will take the original data that was given by the search engine
      # and map, process and group them into the IDs for the overall and grouped results.
      def process_original_ids
        
        # Take the original (raw) set of data and either get the required ID from the data or map to compound IDs of 
        # all objects required according to the scopes specified.
        # Ordering is important and must be taken into account here!
        
        @original_search_docs.each do |doc|
          doc_model_name = Mapper.split_compound_id(doc['id']).first
          
          @result_scopes.map {|r| @internal_scopes_to_and_from_model_names_map[r]}.each do |result_model_name|
            if doc_model_name == result_model_name
              @overall_results_ids << doc['id']
            else
              # This will first look for the presence of the ID in the original doc,
              # in the form of "associated_{object_type}_id_r_id" (the "_r_id" part is due to the way 
              # the field type is stored in Solr by the acts_as_solr plugin).
              # If not present it will use the Mapper to get it.
              id = doc["associated_#{result_model_name.underscore}_id_r_id"]
              if SEARCH_PERFORM_POST_SOLR_MAPPINGS && id.blank?
                id = Mapper.map_compound_id_to_associated_model_object_id(doc['id'], result_model_name)
              end
              
              @overall_results_ids << Mapper.compound_id_for(result_model_name, id) unless id.nil? 
            end
          end
        end
        
        # =============================================
        # OLD - This was the previous sorting algorithm
        # ---------------------------------------------
        
        # Remove duplicates but sort it first.
        #
        # The algorithm for sort does this: it takes the collections of compound IDs found and
        # creates a new array of arrays to group all the duplicate IDs, but at the same time retain the original order of items.
        # Then the main array is sorted by the lengths of the internal arrays, so as to reorder by the number of duplicate entries.
        # Finally a new item IDs array is produced with this new sort order.
        # E.g (note: the numeric IDs below should be string based compound IDs, but the same principles apply):
        #   For the item ID list - [ 5, 6, 12, 3, 3, 5, 5, 21, 2, 6, 3, 6, 6, 6, 6, 10  ]
        #   ... it converts it to - [ [ 5, 5, 5 ], [ 6, 6, 6, 6, 6, 6 ], [ 12 ], [ 3, 3, 3 ], [ 21 ], [ 2 ], [ 10 ] ]
        #   ... then to - [ [ 6, 6, 6, 6, 6, 6 ], [ 5, 5, 5 ], [ 3, 3, 3 ], [ 12 ], [ 21 ], [ 2 ], [ 10 ] ]
        #   ... finally to - [ 6, 5, 3, 12, 21, 2, 10 ]
        #
        # TODO: take into account scores from the search engine.
#        sorted = [ ]
#          
#        @overall_results_ids.each do |item_id|
#          added = false
#          
#          sorted.each do |s|
#            if s.include?(item_id)
#              s << item_id
#              added = true
#            end
#          end
#          
#          unless added
#            sorted[sorted.length] = [ item_id ]
#          end
#        end
#        
#        sorted.sort! { |x,y| y.length <=> x.length }
#        
#        new_results = sorted.map { |s| s.first }
#        
#        @overall_results_ids = new_results
        
        # =============================================

        # Remove duplicates
        @overall_results_ids.uniq!
        
        # Now do the grouped results...
        
        @overall_results_ids.each do |compound_id|
          model_name, id = Mapper.split_compound_id(compound_id)
          search_scope = @internal_scopes_to_and_from_model_names_map[model_name]
          @grouped_results_ids[search_scope] = [ ] unless @grouped_results_ids.has_key?(search_scope)
          @grouped_results_ids[search_scope] << id
        end
        
        # Set total now
        @total = @overall_results_ids.length
        
      end
      
    end
    
    # =======================
    
  end
end