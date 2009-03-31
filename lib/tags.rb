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
    
    # This takes in a collection of 'tags' in the format of the general tag data structure described above.
    #
    # This method has been shamelessly borrowed from the tag_cloud_helper plugin - http://github.com/sgarza/tag_cloud_helper/tree/master
    # but modified and adapted for BioCatalogue by Jits on 2009-02-06
    #
    # Options:
    #   :tag_cloud_style - additional styles to add to the tag_cloud div.
    #     default: ''
    #   :tag_style - additional styles to add to each tag element in the cloud.
    #     default: ''
    #   :min_font - the minimum font size (in px) to use.
    #     default: 10
    #   :max_font - the maximum font size (in px) to use.
    #     default: 30
    def self.tag_cloud(tags, *args)
      return "" if tags.blank?
      
      # Do options the Rails Way ;-)
      options = args.extract_options!
      # defaults:
      options.reverse_merge!(:tag_cloud_style => "",
                             :tag_style => "",
                             :min_font => 10,
                             :max_font => 30)
      
      # Sort by count
      tags.sort! { |a,b| b["count"].to_i <=> a["count"].to_i }
      
      maxlog = Math.log(tags.first['count'])
      minlog = Math.log(tags.last['count'])
      rangelog = maxlog - minlog;
      rangelog = 1 if maxlog==minlog
      min_font = options[:min_font]
      max_font = options[:max_font]
      font_range = max_font - min_font
      
      # Sort by tag name
      tags.sort! { |a,b| a["name"].downcase <=> b["name"].downcase }
      
      cloud = []
  
      tags.each do |tag|
        font_size = min_font + font_range * ((Math.log(tag['count']) - minlog) / rangelog)
        cloud << [tag['name'], font_size.to_i, tag['count']] 
      end
      
      unless cloud.blank?
        output = "<div class=\"tag_cloud\" style=\"#{options[:tag_cloud_style]}\">"

        cloud.each do |tag_name,fsize,count|
          output <<    "<span>"
          output <<    "<a title=\"#{count}\""
          output <<        "alt=\"#{count}\""
          output <<        "class=\"tag\" "
          output <<        "style=\"font-size:#{fsize}px; #{options[:tag_style]}\""
          output <<        "href=\"/tags/#{CGI.escape(tag_name)}\">"
          output <<        CGI.escapeHTML(tag_name) + " "
          output <<    "</a>"
          output <<    "</span>"
        end 
        output << "</div>"
      end
      
      return output
    end
  end
end