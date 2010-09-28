# BioCatalogue: lib/bio_catalogue/tags.rb
#
# Copyright (c) 2008, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

module BioCatalogue
  module Tags
    
    TAG_NAMESPACES = { "http://www.mygrid.org.uk/ontology" => "mygrid-domain-ontology", 
                       "http://www.mygrid.org.uk/mygrid-moby-service" => "mygrid-service-ontology" }.freeze
    
    # ==============================
    # IMPORTANT - Tags data structure
    # ------------------------------
    # A simple (but extensible) data structure will be used to represent tags in the system.
    # This is essentially a view over the annotations in the database.
    #
    # This data structure takes the form of an array of hashes where each hash contains data for a single tag. 
    # Each hash contains:
    # - "name" - the tag name.
    # - "count" - specifies the popularity of that tag (ie: how many items are tagged with that value).
    # - "submitters" (optional) - an array of unique compound IDs (eg: "User:10") that identify the submitters of this particular tag. 
    #     NOTE: This may not necessarily be ALL the submitters of that specific tag in the system since sometimes a 
    #     set of tags will be scoped to something specific (eg: a particular Service).
    #
    # E.g.: 
    #   [ { "name" => "blast", 
    #       "count" => 34, 
    #       "submitters" => [ "User:15", "Registry:11", "User:45" ] },
    #     { "name" => "fasta", 
    #       "count" => 54, 
    #       "submitters" => [ "Registry:11", "User:1" ] }, 
    #   ... ]
    # ==============================
    


    # Retrieves the IDs of all the services that have the specified tag (on any part of the substructure).
    def self.get_service_ids_for_tag(tag_name)
      # NOTE: this query has only been tested to work with MySQL 5.0.x
      sql = [ "SELECT annotations.annotatable_id AS id, annotations.annotatable_type AS type
              FROM annotations 
              INNER JOIN annotation_attributes ON annotations.attribute_id = annotation_attributes.id
              WHERE annotation_attributes.name = 'tag' AND annotations.value = ?",
              tag_name ]
      
      results = ActiveRecord::Base.connection.select_all(ActiveRecord::Base.send(:sanitize_sql, sql))
      
      return BioCatalogue::Mapper.process_compound_ids_to_associated_model_object_ids(results.map{|r| BioCatalogue::Mapper.compound_id_for(r['type'], r['id']) }, "Service").uniq 
    end

    # Takes in a set of annotations and returns a collection of tags
    # The return format is the general tag data structure described above, INCLUDING the "submitters".
    # NOTE (1): these are sorted by tag name.
    def self.annotations_to_tags_structure(annotations)
      return [ ] if annotations.blank?
      
      tags = [ ]
      
      annotations.each do |ann|
        if ann.attribute_name.downcase == "tag"
          found = false
          
          # Try and find it in the tags collection (if it was added previously).
          # MUST take into account tags with different case (must treat them in a case-insensitive way).
          tags.each do |t|
            if t["name"].downcase == ann.value.downcase
              found = true
              t["count"] = t["count"] + 1
              t["submitters"] << BioCatalogue::Mapper.compound_id_for(ann.source_type, ann.source_id)
            end
          end
          
          # If it wasn't found, add it in the tags collection.
          unless found
            tags << { "name" => ann.value, "count" => 1, "submitters" => [ BioCatalogue::Mapper.compound_id_for(ann.source_type, ann.source_id) ] }
          end
        end
      end
      
      return self.sort_tags_alphabetically(tags)
    end
    
    def self.get_total_tags_count
      # NOTE: this query has only been tested to work with MySQL 5.0.x and 5.1.x
#      sql = "SELECT COUNT(DISTINCT annotations.value) AS count 
#            FROM annotations 
#            INNER JOIN annotation_attributes ON annotations.attribute_id = annotation_attributes.id 
#            WHERE annotation_attributes.name = 'tag'"
      
      sql = "SELECT COUNT(*) AS count 
            FROM (SELECT DISTINCT annotations.value FROM annotations 
            INNER JOIN annotation_attributes ON annotations.attribute_id = annotation_attributes.id 
            WHERE annotation_attributes.name = 'tag') x"
            
      ActiveRecord::Base.connection.select_one(sql)['count'].to_i
    end
    
    def self.get_total_items_count_for_tag_name(tag_name)
      # NOTE: this query has only been tested to work with MySQL 5.0.x
      sql = [ "SELECT COUNT(*) as count 
              FROM (SELECT annotations.id FROM annotations 
              INNER JOIN annotation_attributes ON annotations.attribute_id = annotation_attributes.id 
              WHERE annotation_attributes.name = 'tag' AND annotations.value = ?) x",
              "#{tag_name}" ]
      
      return ActiveRecord::Base.connection.select_one(ActiveRecord::Base.send(:sanitize_sql, sql))['count'].to_i
    end
    
    def self.get_total_taggings_count
      Annotation.count(:conditions => { :annotation_attributes => { :name => "tag" } }, :joins => :attribute)
    end
    
    # This will return a set of tags found from the annotations in the database.
    # The return format is the general tag data structure described above, EXCLUDING the "submitters".
    #
    # Default sort order is by counts of things.
    #
    # Supports limiting the results set AND pagination.
    # For performance reasons it is advised to use both in conjunction 
    # (so for example: "I just need the top 100 tags, paged")
    #
    # Options:
    # - :limit (optional) - default: nil - sets the max number of tags to return (taking into account the sort criteria and any paging options specified).
    # - :sort (optional) - default: :counts - specifies how to sort the results. Options are :name, :counts.
    # - :page (optional) - default: nil - specified which page of results to get back.
    # - :per_page (optional) - default: 10 - specifies the number of results to include per page of results.
    def self.get_tags(*args)
      options = args.extract_options!
      # defaults:
      options.reverse_merge!(:page => nil,
                             :per_page => 10,
                             :sort => :counts,
                             :limit => nil)
                           
      # NOTE: this query has only been tested to work with MySQL 5.0.x and MySQL 5.1.x
      sql = "SELECT annotations.value AS name, COUNT(*) AS count 
            FROM annotations 
            INNER JOIN annotation_attributes ON annotations.attribute_id = annotation_attributes.id 
            WHERE annotation_attributes.name = 'tag' 
            GROUP BY annotations.value"
            
      # Does it need to be ordered?
      # Currently only the :counts sorting option will use SQL based ordering (since :name needs to do some special stuff).
      if options[:sort] == :counts 
        sql += " ORDER BY COUNT(*) DESC"
      end
      
      # If limit has been provided then add that to query BUT only if sort is :counts (:name needs some special processing)
      # This allows customisation of the size of the tag cloud, whilst keeping into account sorting of tags.
      if options[:sort] == :counts && options[:limit] && options[:limit].is_a?(Fixnum) && options[:limit] > 0
        sql += " LIMIT #{options[:limit]}"
      end
      
      results = ActiveRecord::Base.connection.select_all(sql)
      
      results.each { |r| r["count"] = r["count"].to_i }
      
      if options[:sort] == :name
        results = self.sort_tags_alphabetically(results)
        
        # If a limit is specified then return accordingly
        if options[:limit] && options[:limit].is_a?(Fixnum) && options[:limit] > 0
          results = results[0...options[:limit]]
        end
      end
      
      # Now consider pagination, if required...
      # NOTE: to improve performance here: ensure that a :limit => x is set (though for :name sort that won't help much)
      if options[:page]
        results = results.paginate(:page => options[:page], :per_page => options[:per_page])
      end
      
      return results
    end
    
    # This gets ALL the tags in the system is performance intensive 
    # so not recommended for regular Web UI use.
    #
    # NOTE: no sorting etc. is applied to the results.
    def self.get_all_tags
      # NOTE: this query has only been tested to work with MySQL 5.0.x and MySQL 5.1.x
      sql = "SELECT annotations.value AS name, COUNT(*) AS count 
            FROM annotations 
            INNER JOIN annotation_attributes ON annotations.attribute_id = annotation_attributes.id 
            WHERE annotation_attributes.name = 'tag' 
            GROUP BY annotations.value"
            
      return ActiveRecord::Base.connection.select_all(sql)
    end
    
    # Returns an array of suggested tag names given the tag fragment.
    def self.get_tag_suggestions(tag_fragment, limit=nil)
      # NOTE: this query has only been tested to work with MySQL 5.0.x and 5.1.x
      sql = [ "SELECT annotations.value AS name
             FROM annotations 
             INNER JOIN annotation_attributes ON annotations.attribute_id = annotation_attributes.id 
             WHERE annotation_attributes.name = 'tag' AND annotations.value LIKE ?
             GROUP BY annotations.value 
             ORDER BY annotations.value ASC",
             "%#{tag_fragment}%" ]
      
      # If limit has been provided then add that to query
      if !limit.nil? && limit.is_a?(Fixnum) && limit > 0
        sql[0] = sql[0] + " LIMIT #{limit}"
      end
      
      return ActiveRecord::Base.connection.select_all(ActiveRecord::Base.send(:sanitize_sql, sql))
    end
    
    # A special sort method that takes into account special cases like ontological term URIs etc.
    def self.sort_tags_alphabetically(tags)
      return nil if tags.nil?
      
      tags.sort do |a,b|
        a_name = a["name"]
        a_name = self.split_ontology_term_uri(a_name)[1] if self.is_ontology_term_uri?(a_name)
        
        b_name = b["name"]
        b_name = self.split_ontology_term_uri(b_name)[1] if self.is_ontology_term_uri?(b_name)
        
        a_name.downcase <=> b_name.downcase 
      end
    end
    
    def self.sort_tags_by_counts(tags)
      return nil if tags.nil?
      
      tags.sort do |a,b|
        b["count"] <=> a["count"]
      end
    end
    
    # Determines whether a given tag name is an ontology term URI or not.  
    #
    # NOTE (1): the tag name must be enclosed in chevrons (< >) to indicate it is a URI.
    # NOTE (2): the tag name must contain a hash (#) to indicate it is an ontology term URI.
    def self.is_ontology_term_uri?(tag_name)
      return tag_name.starts_with?("<") && tag_name.ends_with?(">") && tag_name.include?("#") 
    end
    
    # Splits a tag name into 2 parts (namespace [based on the base identifier URI]
    # and term keyword) IF it is an ontology term URI.
    #
    # Returns an Array where the first item is the namespace and the second is the term keyword.
    # 
    # NOTE (1): the chevrons (< >) will be removed from the resulting split.
    # NOTE (2): it is assumed that the term keyword is the word(s) after a hash ('#')
    def self.split_ontology_term_uri(tag_name)
      namespace = ""
      term_keyword = ""
      if self.is_ontology_term_uri?(tag_name)
        base_uri, term_keyword = tag_name.gsub(/[<>]/, "").split("#")
        if TAG_NAMESPACES.has_key?(base_uri.downcase)
          namespace = TAG_NAMESPACES[base_uri]
        else
          term_keyword = tag_name
        end
      else
        term_keyword = tag_name
      end
      return [ namespace, term_keyword ]
    end
    
    # Given a tag name, this generates the appropriate URL to show the tag results for that tag name.
    def self.generate_tag_show_uri(tag_name)
      url = ""
      
      if BioCatalogue::Tags.is_ontology_term_uri?(tag_name)
        namespace, keyword = BioCatalogue::Tags.split_ontology_term_uri(tag_name)
        url = "/tags/#{URI::escape(keyword)}?#{namespace.to_query("namespace")}"
      else
        url = "/tags/#{URI::escape(tag_name)}"
      end
      
       return url
    end
    
    # This method works out the exact tag name from the parameters provided 
    # (these should be the params hash that ActionController generates from query string data and POST data).
    def self.get_tag_name_from_params(params)
      tag_name = ""
      
      tag_name = URI::unescape(params[:tag_keyword])
      
      return tag_name if tag_name.blank?
      
      # Check for namespace
      unless (namespace = params[:namespace]).blank?
        namespace = namespace.downcase
        identifier_uri = ''
        if TAG_NAMESPACES.values.include?(namespace)
          TAG_NAMESPACES.each do |k,v|
            identifier_uri = k if v == namespace
          end
          tag_name = "<#{URI::unescape(identifier_uri)}##{tag_name}>"
        end
      end
      
      return tag_name
    end
    
  end
end