# BioCatalogue: lib/bio_catalogue/tags.rb
#
# Copyright (c) 2008, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

module BioCatalogue
  module Tags
    
    TAG_NAMESPACES = { "http://www.mygrid.org.uk/ontology" => "mygrid-domain", 
                       "http://www.mygrid.org.uk/mygrid-moby-service" => "mygrid-service" }.freeze
    
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
      
      return BioCatalogue::Mapper.process_compound_ids_to_associated_model_object_ids(results.map{|r| "#{r['type']}:#{r['id'].to_s}" }, "Service").uniq 
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
              t["submitters"] << "#{ann.source_type}:#{ann.source_id}"
            end
          end
          
          # If it wasn't found, add it in the tags collection.
          unless found
            tags << { "name" => ann.value, "count" => 1, "submitters" => [ "#{ann.source_type}:#{ann.source_id}" ] }
          end
        end
      end
      
      return self.sort_tags_alphabetically(tags)
    end
    
    # This will return a set of tags found from the annotations in the database.
    # The return format is the general tag data structure described above, EXCLUDING the "submitters".
    # NOTE (1): these are sorted by tag name.
    def self.get_tags(limit=nil)
      # NOTE: this query has only been tested to work with MySQL 5.0.x
      sql = "SELECT annotations.value AS name, COUNT(*) AS count 
            FROM annotations 
            INNER JOIN annotation_attributes ON annotations.attribute_id = annotation_attributes.id 
            WHERE annotation_attributes.name = 'tag' 
            GROUP BY annotations.value 
            ORDER BY COUNT(*) DESC"
      
      # If limit has been provided then add that to query
      # (this allows customisation of the size of the tag cloud, whilst keeping into account ranking of tags).
      if !limit.nil? && limit.is_a?(Fixnum) && limit > 0
        sql += " LIMIT #{limit}"
      end
      
      results = ActiveRecord::Base.connection.select_all(sql)
      
      results = results.each do |r|
        r["count"] = r["count"].to_i
      end
       
      return self.sort_tags_alphabetically(results)
    end
    
    # Returns an array of suggested tag names given the tag fragment.
    def self.get_tag_suggestions(tag_fragment, limit=nil)
      # NOTE: this query has only been tested to work with MySQL 5.0.x
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
    
    def self.sort_tags_by_frequency(tags)
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
      tag_name  = ""
      
      tag_name = URI::unescape(params[:tag_keyword])
    
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