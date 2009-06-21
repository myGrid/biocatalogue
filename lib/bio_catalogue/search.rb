# BioCatalogue: lib/bio_catalogue/search.rb
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

module BioCatalogue
  module Search
    
    # MUST correspond to pluralised and underscored model names.
    VALID_SEARCH_TYPES = [ "services", "service_providers", "users", "registries" ].freeze
    
    ALL_TYPES_SYNONYMS = [ "all", "any" ].freeze
    
    # As new models are indexed (and therefore need to be searched on) add them here.
    @@models_for_search_types = { "all" => Mapper::SERVICE_STRUCTURE_MODELS + [ ServiceProvider, User, Registry, Annotation ],
                                  "services" => Mapper::SERVICE_STRUCTURE_MODELS + [ Annotation ],
                                  "service_providers" => [ ServiceProvider ],
                                  "users" => [ User ],
                                  "registries" => [ Registry ]}.freeze
    
    @@search_query_suggestions_file_path = File.join(Rails.root, 'data', 'search_query_suggestions.txt')
    
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
          excludes = [ "*", "[object htmlcollection]" ]
          terms.reject!{|t| excludes.include?(t)}
          
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
    
    def self.search_all(query)
      query = self.preprocess_query(query)
      
      limit = 5000
      
      models = @@models_for_search_types["all"]
      search_result_docs = models.first.multi_solr_search(query, :limit => limit, :models => models[1...models.length], :results_format => :ids).docs
        
      return Results.new(search_result_docs, VALID_SEARCH_TYPES)
    end
    
    def self.search(query, type)
      return self.search_all(query) if ALL_TYPES_SYNONYMS.include?(type.downcase)
      return nil unless VALID_SEARCH_TYPES.include?(type.downcase)
      
      query = self.preprocess_query(query)
      
      limit = 2000
      
      models = @@models_for_search_types[type]
      
      search_result_docs = [ ]
      
      unless models.blank?
        if models.length == 1
          # Only one model to look for...
          search_result_docs = models.first.find_id_by_solr(query).docs
        else
          # Multiple models to search for, to collect results for the type requested...
          search_result_docs = models.first.multi_solr_search(query, :limit => limit, :models => models[1...models.length], :results_format => :ids).docs
        end
      end
      
      return Results.new(search_result_docs, [ type ])
    end
    
    # =======================
    # Class to handle results
    # -----------------------
    
    # Takes care of processing the raw results from the search engine to useful results for the system,
    # taking into account the specified types the raw results should be mapped, processed and grouped into.
    #
    # Takes care of things like mapping SoapOperation results to ancestor Services and so on.
    #
    # Note (1): this only deals with the IDs of objects and never fetches any of the objects from the db directly.
    # Note (2): internally this reads, stores and works with the "compound ID" format: "{model_name}:{id}" to disambiguate between different items.
    class Results
      
      attr_reader :total,         # The total number of search results, regardless of types. Integer.
                  :result_types   # The types that the results should be processed and grouped into. Array of Strings, that correspond to pluralised and underscored model names.
      
      # Internal variables to store original search results...
      @original_search_docs = [ ]    # The original docs from the search engine.
      @original_ids = [ ]            # Array of Strings (eg: [ "Service:101", "ServiceDeployment:45", "User:6", "User:8" ])
      
      # Internal variables to store processed and grouped results...
      @grouped_results_ids = { }     # Hash, where keys are the search types (pluralised and underscored model names) and values are Arrays of IDs of the objects for that type. 

      # Object initializer
      #
      # search_docs
      #   the raw docs from the search engine (either an empty Array, Array of Integer IDs, or an Array of String IDs in the compound ID format "{model_name}:{id}").
      # 
      # types
      #   the search types (pluralised and underscored model names) that this Results set needs to deal with.
      #
      def initialize(search_docs, types)
        @original_search_docs = Marshal.load(Marshal.dump(search_docs))
        
        @result_types = types
        
        if @original_search_docs.first.kind_of?(Integer)
          # If the search docs only contain integers then we know that they are all of one type. 
          # In which case only one type should be specified in 'types'.
          
          if types.length != 1
            raise "Cannot create results for more than one search type when only given a set of numerical IDs in the search docs. How am I supposed to determine what model these IDs are for huh? Huh, punk?"
          else
            model_name = @result_types.first.classify
            @original_ids = @original_search_docs.map { |r| "#{model_name}:#{r}" }
          end
        elsif @original_search_docs.first.kind_of?(Hash)
          @original_ids = @original_search_docs.map { |r| r["id"] }
        else
          @original_ids = [ ]
        end
        
        @grouped_results_ids = { }
        
        process_original_ids
      end
      
      # Gets all the item IDs for the specified result type.
      def all_item_ids(result_type)
        return @grouped_results_ids[result_type] || [ ]
      end
      
      # Gets the paged item IDs for the specified result type.
      def item_ids(result_type, page)
        x = all_item_ids(result_type)
        return x.paginate(:page => page, :per_page => PAGE_ITEMS_SIZE) 
      end
      
      # Gets the count of items for a specified result type. 
      # If the result is invalid then 0 is returned. 
      def count(result_type)
        return @grouped_results_ids[result_type].try(:length) || 0
      end
      
      protected
      
      # This method will take the original IDs that were given by the search engine
      # and map, process and group them them into the IDs for the types of search results 
      # actually required.
      def process_original_ids
        # Map and group raw results
        @result_types.each do |result_type|
          result_model_name = result_type.classify
          @grouped_results_ids[result_type] = Mapper.process_compound_ids_to_associated_model_object_ids(@original_ids, result_model_name)
        end
        
        # Sort (by number of duplicates results and initial order) and then remove duplicates.
        #
        # The algorithm for sort does this: for each search type, it takes the collections of item IDs found and
        # creates a new array of arrays to group all the duplicate IDs, but at the same time retain the original order of items.
        # Then the main array is sorted by the lengths of the internal arrays, so as to reorder by the number of duplicate entries.
        # Finally a new item IDs array is produced with this new sort order.
        # E.g:
        #   For the item ID list - [ 5, 6, 12, 3, 3, 5, 5, 21, 2, 6, 3, 6, 6, 6, 6, 10  ]
        #   ... it converts it to - [ [ 5, 5, 5 ], [ 6, 6, 6, 6, 6, 6 ], [ 12 ], [ 3, 3, 3 ], [ 21 ], [ 2 ], [ 10 ] ]
        #   ... then to - [ [ 6, 6, 6, 6, 6, 6 ], [ 5, 5, 5 ], [ 3, 3, 3 ], [ 12 ], [ 21 ], [ 2 ], [ 10 ] ]
        #   ... finally to - [ 6, 5, 3, 12, 21, 2, 10 ]
        #
        # TODO: take into account scores from the search engine.
        @grouped_results_ids.each do |search_type, item_ids|
          sorted = [ ]
          
          item_ids.each do |item_id|
            added = false
            
            sorted.each do |s|
              if s.include?(item_id)
                s << item_id
                added = true
              end
            end
            
            unless added
              sorted[sorted.length] = [ item_id ]
            end
          end
          
          sorted.sort! { |x,y| y.length <=> x.length }
          
          new_results = sorted.map { |s| s.first }
          
          @grouped_results_ids[search_type] = new_results
        end
        
        # Set total now
        @total = 0
        @grouped_results_ids.values.each do |item_ids|
          @total += item_ids.length
        end
      end
      
    end
    
    # =======================
    
  end
end