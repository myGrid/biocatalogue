# BioCatalogue: lib/bio_catalogue/tags.rb
#
# Copyright (c) 2008-2011, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

module BioCatalogue
  module Tags
    
    TAG_NAMESPACES = { "http://www.mygrid.org.uk/ontology" => "mygrid-domain-ontology", 
                       "http://www.mygrid.org.uk/mygrid-moby-service" => "mygrid-service-ontology" }.freeze
    
    # ====================================
    # IMPORTANT - Tags hash data structure
    # ------------------------------------
    # A simple (but extensible) data structure will be used to represent tags in the system.
    # This is essentially a view over the entities in the 'annotations' and 'tags' tables in the database.
    #
    # This data structure takes the form of an array of hashes where each hash contains data for a single tag. 
    # Each hash contains:
    # - "name" - the tag's full name.
    # - "label" - the tag's label.
    # - "count" - specifies the popularity of that tag within a particular context (i.e.: how many items are tagged with that value).
    # - "submitters" (optional) - an array of unique compound IDs (eg: "User:10") that identify the submitters of this particular tag. 
    #     NOTE: This may not necessarily be ALL the submitters of that specific tag in the system since sometimes a 
    #     set of tags will be scoped to something specific (eg: a particular Service).
    #
    # E.g.: 
    #   [ { "name" => "blast",
    #       "label" => "blast",
    #       "count" => 34, 
    #       "submitters" => [ "User:15", "Registry:11", "User:45" ] },
    #     { "name" => "http://myontology.org/fasta",
    #       "label" => "fasta",
    #       "count" => 54, 
    #       "submitters" => [ "Registry:11", "User:1" ] }, 
    #   ... ]
    # ====================================
    

    # Retrieves the IDs of all the services that have the specified tag, on any part of the substructure.
    def self.get_service_ids_for_tag(tag_name)
      sql = [ "SELECT annotations.annotatable_id AS id, annotations.annotatable_type AS type
              FROM annotations 
              INNER JOIN annotation_attributes ON annotations.attribute_id = annotation_attributes.id
              INNER JOIN tags ON tags.id = annotations.value_id AND annotations.value_type = 'Tag'
              WHERE annotation_attributes.name = 'tag' AND tags.name = ?",
              tag_name ]
      
      results = Tag.connection.select_all(Tag.send(:sanitize_sql, sql))
      
      return BioCatalogue::Mapper.process_compound_ids_to_associated_model_object_ids(results.map{|r| BioCatalogue::Mapper.compound_id_for(r['type'], r['id']) }, "Service").uniq 
    end

    # Takes in a set of annotations and returns a collection of tags in the tags hash data structure 
    # described above, INCLUDING the "submitters".
    #
    # NOTE (1): these are sorted by tag label.
    def self.annotations_to_tags_structure(annotations)
      return [ ] if annotations.blank?
      
      tags = [ ]
      
      annotations.each do |ann|
        if ann.attribute_name.downcase == "tag" && ann.value_type == "Tag"
          found = false
          
          submitter_compound_id = BioCatalogue::Mapper.compound_id_for(ann.source_type, ann.source_id)
          
          # MUST take into account tags with different case (must treat them in a case-insensitive way).
          tags.each do |t|
            if t["name"].downcase == ann.value.name.downcase
              found = true
              t["count"] = t["count"] + 1
              t["submitters"] << submitter_compound_id unless t["submitters"].include?(submitter_compound_id) 
            end
          end
          
          unless found
            tags << { 
              "name" => ann.value.name,
              "label" => ann.value.label,
              "count" => 1,
              "submitters" => [ submitter_compound_id ] 
            }
          end
        end
      end
      
      return tags.sort { |x,y| x['label'] <=> y['label'] }
    end
    
    def self.get_total_items_count_for_tag_name(tag_name)
      sql = [ "SELECT COUNT(*) as count
              FROM (SELECT annotations.id
              FROM annotations
              INNER JOIN annotation_attributes ON annotations.attribute_id = annotation_attributes.id
              INNER JOIN tags ON tags.id = annotations.value_id AND annotations.value_type = 'Tag'
              WHERE annotation_attributes.name = 'tag' AND tags.name = ?
              GROUP BY annotations.annotatable_type, annotations.annotatable_id) x",
              tag_name ]
              
      return Tag.connection.select_one(Tag.send(:sanitize_sql, sql))['count'].to_i
    end
    
    def self.get_total_taggings_count
      Annotation.count(:conditions => { :annotation_attributes => { :name => "tag" } }, :joins => :attribute)
    end
    
    def self.get_total_tags_count
      sql = "SELECT COUNT(*) AS count
            FROM (
            SELECT DISTINCT tags.id, annotations.annotatable_type, annotations.annotatable_id
            FROM annotations
            INNER JOIN annotation_attributes ON annotations.attribute_id = annotation_attributes.id
            INNER JOIN tags ON tags.id = annotations.value_id AND annotations.value_type = 'Tag'
            WHERE annotation_attributes.name = 'tag'
            GROUP BY tags.id) AS x"
              
      return Tag.connection.select_one(Tag.send(:sanitize_sql, sql))['count'].to_i
    end
    
    # This is a wrapper method around the Tag model to:
    # a) Only return Tags that have been used in the system. (So ignores empty tags).
    # b) Convert the data into the common tags hash data structure used throughout.
    #
    # Returns a collection of tags in the tags hash data structure described above, 
    # EXCLUDING the "submitters".
    #
    # NOTE: this method comes from a legacy from back in the era when Annotation objects 
    # had simple string values instead of polymorphic object-based values.
    #
    # Default sort order is by unique counts of things.
    #
    # Supports limiting the results set OR pagination.
    #
    # Options:
    # - :limit (optional) - default: nil - sets the max number of tags to return. Cannot be used with the paging options (:page takes priority).
    # - :sort (optional) - default: :counts - specifies how to sort the results. Options are:
    #     - :name (which actually sorts by the label of the Tag) 
    #     - :counts
    # - :page (optional) - default: nil - specified which page of results to get back. Cannot be used with the :limit option (:page takes priority).
    # - :per_page (optional) - default: 10 - specifies the number of results to include per page of results. Cannot be used with the :limit option (:page takes priority).
    def self.get_tags(*args)
      options = args.extract_options!
      # defaults:
      options.reverse_merge!(:page => nil,
                             :per_page => 10,
                             :sort => :counts,
                             :limit => nil)
      
      unless [ :counts, :name ].include?(options[:sort])
        raise ArgumentError, 'Invalid :sort option provided'
      end
      
      unless options[:limit].nil? || (options[:limit].is_a?(Fixnum) && options[:limit] > 0)
        raise ArgumentError, 'Invalid :limit option provided'
      end
      
      sql = "SELECT tags.name, tags.label, COUNT(DISTINCT annotations.annotatable_type, annotations.annotatable_id) AS count
            FROM annotations
            INNER JOIN annotation_attributes ON annotations.attribute_id = annotation_attributes.id
            INNER JOIN tags ON tags.id = annotations.value_id AND annotations.value_type = 'Tag'
            WHERE annotation_attributes.name = 'tag'
            GROUP BY tags.id"
            
      # Sorting
      sql += case options[:sort]
        when :name
          " ORDER BY label ASC"
        when :counts
          " ORDER BY count DESC, label ASC"
      end
      
      # Paging OR limit
      if options[:page]
        start = (options[:page]-1)*options[:per_page]
        sql += " LIMIT #{start},#{options[:per_page]}"
      else
        if options[:limit]
          sql += " LIMIT #{options[:limit]}"
        end
      end

      results = Tag.connection.select_all(sql)
      
      results.each { |r| r["count"] = r["count"].to_i }
      
      return results
    end
    
    # Returns an array of suggested tag names given the tag fragment.
    # NOTE: only takes into account tags that are actually being used in the system.
    def self.get_tag_suggestions(tag_fragment, limit=nil)
      sql = [
        "SELECT tags.name
        FROM annotations
        INNER JOIN annotation_attributes ON annotations.attribute_id = annotation_attributes.id
        INNER JOIN tags ON tags.id = annotations.value_id AND annotations.value_type = 'Tag'
        WHERE annotation_attributes.name = 'tag' AND tags.name LIKE ?
        GROUP BY tags.id
        ORDER BY tags.label ASC",
        "%#{tag_fragment}%"
      ]
      
      # If limit has been provided then add that to query
      if !limit.nil? && limit.is_a?(Fixnum) && limit > 0
        sql[0] = sql[0] + " LIMIT #{limit}"
      end
      
      return Tag.connection.select_all(Tag.send(:sanitize_sql, sql))
    end
    
    # Determines whether a given term URI is an ontology term URI or not,
    # based on some rudimentary rules.  
    #
    # NOTE (1): the tag name must be enclosed in chevrons (< >) to indicate it is a URI.
    # NOTE (2): the tag name must contain a hash (#) to indicate it is an ontology term URI.
    def self.is_ontology_term_uri?(term_uri)
      return term_uri.starts_with?("<") && term_uri.ends_with?(">") && term_uri.include?("#") 
    end
    
    def self.split_ontology_term_uri(term_uri)
      namespace = ""
      term_keyword = ""
      if self.is_ontology_term_uri?(term_uri)
        base_uri, term_keyword = term_uri.gsub(/[<>]/, "").split("#")
        if TAG_NAMESPACES.has_key?(base_uri.downcase)
          namespace = TAG_NAMESPACES[base_uri]
        else
          term_keyword = term_uri
        end
      else
        term_keyword = term_uri
      end
      return [ namespace, term_keyword ]
    end
    
    # Given a tag name, this generates the appropriate URL to show the tag results for that tag name.
    def self.generate_tag_show_uri(tag_name)
      url = ""
      
      if BioCatalogue::Tags.is_ontology_term_uri?(tag_name)
        namespace, keyword = BioCatalogue::Tags.split_ontology_term_uri(tag_name)
        url = "/tags/#{URI::escape(keyword, "/")}?#{namespace.to_query("namespace")}"
      else
        url = "/tags/#{URI::escape(tag_name, "/")}"
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