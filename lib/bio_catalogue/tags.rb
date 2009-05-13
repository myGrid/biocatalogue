# BioCatalogue: lib/bio_catalogue/tags.rb
#
# Copyright (c) 2008, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

module BioCatalogue
  module Tags
    
    @@logger = RAILS_DEFAULT_LOGGER
    
    # ==============================
    # IMPORTANT - Tag data structure
    # ------------------------------
    # A simple (but extensible) data structure will be used to represent tags in the system.
    # This is essentially a view over the annotations in the database.
    #
    # This data structure takes the form of an array of hashes where each hash contains data for a single tag. 
    # Each hash contains a "name" field (ie: the tag name), and a "count" field to specify 
    # the popularity of that tag (ie: how many items are tagged with that value).
    #
    # E.g.: [ { "name" => "blast", "count" => "34" }, { "name" => "fasta", "count" => "54" } ... ]
    # ==============================
    

    # Takes in a set of annotations and returns a collection of tags
    # in the format of the general tag data structure described above.
    # NOTE (1): these are sorted by tag name.
    def self.annotations_to_tags_structure(annotations)
      return [ ] if annotations.blank?
      
      tags = [ ]
      
      annotations.each do |ann|
        if ann.attribute_name.downcase == "tag"
          found = false
          
          # Try and find it in the tags collection (if it was added previously)
          tags.each do |t|
            if t["name"].downcase == ann.value.downcase
              found = true
              t["count"] = t["count"] + 1
            end
          end
          
          # If it wasn't found, add it in the tags collection.
          unless found
            tags << Hash[ "name" => ann.value, "count" => 1 ]
          end
        end
      end
      
      return self.sort_tags_alphabetically(tags)
    end
    
    # This will return a set of tags found from the annotations in the database.
    # The return format is the general tag data structure described above.
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
       
      return self.sort_tags_alphabetically(ActiveRecord::Base.connection.select_all(sql))
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
    
    # Determines whether a given tag name is an ontology term URI or not.  
    #
    # NOTE (1): the tag name must be enclosed in chevrons (< >) to indicate it is a URI.
    # NOTE (2): the tag name must contain a hash (#) to indicate it is an ontology term URI.
    def self.is_ontology_term_uri?(tag_name)
      return tag_name.starts_with?("<") && tag_name.ends_with?(">") && tag_name.include?("#") 
    end
    
    # Splits a tag name into 2 parts (base identifier URI and term keyword) IF it is an ontology term URI.
    # 
    # NOTE (1): the chevrons (< >) will be removed from the resulting split.
    # NOTE (2): it is assumed that the term keyword is the word(s) after a hash ('#')
    def self.split_ontology_term_uri(tag_name)
      if self.is_ontology_term_uri?(tag_name)
        return tag_name.gsub(/[<>]/, "").split("#")
      else
        return tag_name
      end
    end
    
    # Given a tag name, this generates the appropriate URL to show the tag results for that tag name.
    def self.generate_tag_show_uri(tag_name)
      url = ""
      
      if BioCatalogue::Tags.is_ontology_term_uri?(tag_name)
        base_identifier_uri, keyword = BioCatalogue::Tags.split_ontology_term_uri(tag_name)
        url = "/tags/#{URI::escape(keyword)}?#{base_identifier_uri.to_query("identifier_uri")}"
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
    
      # Check for base identifier URI
      if params[:identifier_uri]
        tag_name = "<#{URI::unescape(params[:identifier_uri])}##{tag_name}>"
      end
      
      return tag_name
    end
  end
end