# BioCatalogue: lib/bio_catalogue/search.rb
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

module BioCatalogue
  module Search
    
    # MUST correspond to pluralised and underscored model names.
    VALID_SEARCH_SCOPES = [ "services", "soap_operations", "rest_methods", "service_providers", "users", "registries" ].freeze
    
    ALL_SCOPE_SYNONYMS = [ "all", "any" ].freeze
    
    VALID_SEARCH_SCOPES_INCL_ALL = ([ ALL_SCOPE_SYNONYMS[0] ] + VALID_SEARCH_SCOPES).freeze
    
    # As new models are indexed (and therefore need to be searched on) add them here.
    @@models_for_search = (Mapper::SERVICE_STRUCTURE_MODELS + [ ServiceProvider, User, Registry, Annotation ]).freeze
    
    @@search_query_suggestions_file_path = File.join(Rails.root, 'data', 'search_query_suggestions.txt')
    
    @@limit = 10000
    
    def self.on?
      return ENABLE_SEARCH
    end
    
    def self.scope_to_visible_search_type(scope)
      return "" if scope.blank?
      case scope  
        when "soap_operations"
          "SOAP Operations"
        when "rest_methods"
          "REST Endpoints"
        else
          scope.titleize
      end
    end
    
    def self.update_search_query_suggestions_file
      begin
        
        search_synonyms = self.all_terms_from_pseudo_synonyms
        
        latest_search_queries = ActivityLog.find_all_by_action("search").map{|a| a.data[:query]}.compact.uniq
        
        categories = Category.all.map{|c| c.name}.compact
        
        tags = BioCatalogue::Tags.get_tags.map{|t| t['name'] unless BioCatalogue::Tags.is_ontology_term_uri?(t['name']) }.compact
        
        unless latest_search_queries.blank? and categories.blank? and tags.blank?
          
          terms = search_synonyms + latest_search_queries + categories + tags
          
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
          
          # Remove duplicates (case insensitive)
          terms = BioCatalogue::Util.uniq_strings_case_insensitive(terms)
          
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
          suggestions << CGI.escapeHTML(t) if s.match(query_fragment)          
        end
        
      rescue Exception => ex
        msg = "Failed to get query suggestions. Error message: #{ex.message}."
        Rails.logger.error(msg)
        puts(msg)
      end
      
      return suggestions.map{|s| { 'name' => s }}
    end
    
    # The main search method.
    #
    # 'scope' can be a string representing one of the search scopes from VALID_SEARCH_SCOPES_INCL_ALL
    # OR an Array of the different scopes required.
    #
    # NOTE: the results obtained from Solr are cached for SEARCH_ITEMS_FROM_SOLR_CACHE_TIME amount of time 
    # so as to reduce the load coming in from many simultaneous searches of the same query but different scope 
    # (eg: when the BioCatalogue plugin for Taverna searches for Services, SOAP operations, REST endpoints, etc
    # all at the same time but as separate scoped requests).
    def self.search(query, scope=ALL_SCOPE_SYNONYMS[0], ignore_scope=nil)
      return nil unless Search.on?
      
      return nil if query.blank? or scope.blank?
      
      return nil if scope == ignore_scope
      
      if scope.is_a? Array
        scope.map! { |s| s.downcase }
        scope.each do |s|
          return nil unless VALID_SEARCH_SCOPES_INCL_ALL.include?(s)
        end
      else
        scope = scope.downcase 
        return nil unless VALID_SEARCH_SCOPES_INCL_ALL.include?(scope)
      end
      
      query = self.preprocess_query(query)
      
      search_result_docs = nil
      
      cache_key = BioCatalogue::CacheHelper.cache_key_for(:search_items_from_solr, query)
      
      # Try and get it from the cache...
      search_result_docs = Rails.cache.read(cache_key)
      
      if search_result_docs.nil?
        search_result_docs = @@models_for_search.first.multi_solr_search(query, 
          :limit => @@limit, 
          :models => @@models_for_search[1...@@models_for_search.length], 
          :results_format => :ids, 
          :incl_all_fields => true).docs
        
        # Finally write it to the cache...
        Rails.cache.write(cache_key, search_result_docs, :expires_in => SEARCH_ITEMS_FROM_SOLR_CACHE_TIME)
      end
      
      scopes_for_results = nil
      
      if scope.is_a? Array 
        scope.each do |s|
          scopes_for_results = VALID_SEARCH_SCOPES if ALL_SCOPE_SYNONYMS.include?(s)
        end
        scopes_for_results = scope if scopes_for_results.nil?
      else      
        scopes_for_results = if ALL_SCOPE_SYNONYMS.include?(scope)
          VALID_SEARCH_SCOPES
        else
          [ scope ]
        end
      end
      
      unless ignore_scope.blank? 
        scopes_for_results = scopes_for_results - [ ignore_scope ].flatten
      end
      
      return Results.new(search_result_docs, scopes_for_results)
    end
    
    # IMPORTANT NOTE: this is a VERY intensive and costly method call,
    # so don't use this within a web request, only use it in background
    # processing, scripts and the console.
    def self.all_possible_activity_logs_for_search(limit_to_fields=[])
      conditions = "action = 'search' OR action LIKE '%index%'"
      if limit_to_fields.blank?
        ActivityLog.find(:all, :conditions => conditions)
      else
        ActivityLog.find(:all, 
                         :select => limit_to_fields.to_sentence(:last_word_connector => ", ", :two_words_connector => ", "), 
                         :conditions => conditions)        
      end
    end
    
    def self.search_term_from_hash(h)
      h[:query] || h[:q] || h['query'] || h['q']
    end
    
    protected
    
    # Special rules to preprocess ALL search queries. 
    #
    # Rules are:
    # - For a query that begins with and ends with double quotes AND
    #   that contains http:// or https:// - the WHOLE query is escaped.
    def self.preprocess_query(query)
      unless query.blank?
        if query.starts_with?('"') and query.ends_with?('"')
          
          # Remove the double quotes for now...
          query = query.slice(1...-1)
          
          if query.include?("http://") or query.include?("https://")
            query = Solr::Util.query_parser_escape(query)
          end
          
          # Add back the double quotes
          query = '"' + query + '"'
        end
      end
      
      return query
    end
    
    def self.all_terms_from_pseudo_synonyms
      synonyms_out = [ ]
      
      filename = File.join(Rails.root, 'data', 'cleaned_up_pseudo_synonyms.txt')
      synonynms_in = IO.read(filename)
         
      unless synonynms_in.nil? or synonynms_in == ''
        synonynms_in.split(/[\n]/).map{|i| i.strip}.each do |line|
          unless line.nil? or line == "\n" or line.strip == "" or line[0,1] == "#"
            lhs_in, rhs_in = line.split("=>")
            
            lhs_in = lhs_in.split(',').compact.map{|i| i.strip}.reject{|i| i == ""}
            rhs_in = rhs_in.split(',').compact.map{|i| i.strip}.reject{|i| i == ""}
            
            synonyms_out.concat(lhs_in + rhs_in)
          end
          
        end
        
      end
      
      return synonyms_out.compact.uniq
    end
    
  end
end