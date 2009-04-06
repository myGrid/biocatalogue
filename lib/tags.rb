# BioCatalogue: app/lib/tags.rb
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
      
      return tags
    end
    
    # This will return a set of tags found from the annotations in the database.
    # The return format is the general tag data structure described above.
    def self.get_tags(limit=nil)
      # NOTE: this query has only been tested to work with MySQL 5.0.x
      sql = "SELECT annotations.value AS name, COUNT(*) AS count 
            FROM annotations 
            INNER JOIN annotation_attributes ON annotations.attribute_id = annotation_attributes.id 
            WHERE annotation_attributes.name = 'tag' 
            GROUP BY annotations.value 
            ORDER BY COUNT(*) DESC"
      
      # If limit has been provided in the URL then add that to query
      # (this allows customisation of the size of the tag cloud, whilst keeping into account ranking of tags).
      if !limit.nil? && limit.is_a?(Fixnum) && limit > 0
        sql += " LIMIT #{limit}"
      end
       
      return ActiveRecord::Base.connection.select_all(sql)
    end
    
  end
end