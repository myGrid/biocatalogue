# BioCatalogue: lib/bio_catalogue/filtering/annotations.rb
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# Module for filtering specific to annotations

module BioCatalogue
  module Filtering
    module Annotations
      
      # ======================
      # Filter options finders
      # ----------------------
  
      def self.get_filters_for_filter_type(filter_type, limit=nil, search_query=nil)
        case filter_type
          when :attrib
            get_filters_for_attributes(limit)
          when :as
            get_filters_for_annotatables("Service", limit)
          when :asd
            get_filters_for_annotatables("ServiceDeployment", limit)
          when :asp
            get_filters_for_annotatables("ServiceProvider", limit)
          when :ars
            get_filters_for_annotatables("RestService", limit)
          when :ass
            get_filters_for_annotatables("SoapService", limit)
          when :asop
            get_filters_for_annotatables("SoapOperation", limit)
          when :asin
            get_filters_for_annotatables("SoapInput", limit)
          when :asout
            get_filters_for_annotatables("SoapOutput", limit)
          when :soa
            get_filters_for_sources("Agent", limit)
          when :sor
            get_filters_for_sources("Registry", limit)
          when :sosp
            get_filters_for_sources("ServiceProvider", limit)
          when :sou
            get_filters_for_sources("User", limit)
          when :arm
            get_filters_for_annotatables("RestMethod", limit)
          when :arp
            get_filters_for_annotatables("RestParameter", limit)
          when :arr
            get_filters_for_annotatables("RestRepresentation", limit)
          when :arres
            get_filters_for_annotatables("RestResource", limit)
          else
            [ ]
        end
      end
      
      # Gets an ordered list of all the annotation attributes and their counts of annotations.
      #
      # Example return data:
      # [ { "id" => "1", "name" => "description", "count" => "181" }, { "id" => "3", "name" => "tag", "count" => "11" }  ... ]
      def self.get_filters_for_attributes(limit=nil)
        # NOTE: this query has only been tested to work with MySQL
        sql = "SELECT annotation_attributes.id AS id, annotation_attributes.identifier AS name, COUNT(*) AS count 
              FROM annotation_attributes 
              INNER JOIN annotations ON annotations.attribute_id = annotation_attributes.id 
              GROUP BY annotation_attributes.id
              ORDER BY COUNT(*) DESC"
        
        # If limit has been provided in the URL then add that to query.
        if !limit.nil? && limit.is_a?(Fixnum) && limit > 0
          sql += " LIMIT #{limit}"
        end
         
        return ActiveRecord::Base.connection.select_all(sql)
      end
      
      # Gets an ordered list of all the annotatable objects, of type 'annotatable_type', and their counts of annotations.
      #
      # Example return data:
      # [ { "id" => "1", "name" => "BlastService", "count" => "181" }, { "id" => "3", "name" => "KeggService", "count" => "11" }  ... ]
      def self.get_filters_for_annotatables(annotatable_type, limit=nil)
        # NOTE: this query has only been tested to work with MySQL
        sql = "SELECT annotations.annotatable_id AS id, COUNT(*) AS count 
              FROM annotations 
              WHERE annotations.annotatable_type = ?
              GROUP BY annotations.annotatable_id
              ORDER BY COUNT(*) DESC"
        
        # If limit has been provided in the URL then add that to query.
        if !limit.nil? && limit.is_a?(Fixnum) && limit > 0
          sql += " LIMIT #{limit}"
        end
         
        results = ActiveRecord::Base.connection.select_all(ActiveRecord::Base.send(:sanitize_sql, [ sql, annotatable_type ]))
        
        # Need to now fetch all these object so we can figure out their display names!
        # TODO: optimize the retrieval of display names
        objs = { }
        item_ids = results.map { |x| x['id'] }
        
        annotatable_type.constantize.find(:all, :conditions => { :id => item_ids }).each do |obj|
          objs[obj.id.to_s] = obj
        end
        
        results.each do |r|
          r['name'] = BioCatalogue::Util.display_name(objs[r['id']], false)
        end
        
        return results
      end
      
      # Gets an ordered list of all the source objects, of type 'source_type', and their counts of annotations.
      #
      # Example return data:
      # [ { "id" => "1", "name" => "Jim", "count" => "181" }, { "id" => "3", "name" => "Katy", "count" => "11" }  ... ]
      def self.get_filters_for_sources(source_type, limit=nil)
        # NOTE: this query has only been tested to work with MySQL
        sql = "SELECT annotations.source_id AS id, COUNT(*) AS count 
              FROM annotations 
              WHERE annotations.source_type = ?
              GROUP BY annotations.source_id
              ORDER BY COUNT(*) DESC"
        
        # If limit has been provided in the URL then add that to query.
        if !limit.nil? && limit.is_a?(Fixnum) && limit > 0
          sql += " LIMIT #{limit}"
        end
         
        results = ActiveRecord::Base.connection.select_all(ActiveRecord::Base.send(:sanitize_sql, [ sql, source_type ]))
        
        # Need to now fetch all these object so we can figure out their display names!
        
        objs = { }
        item_ids = results.map { |x| x['id'] }
        
        source_type.constantize.find(:all, :conditions => { :id => item_ids }).each do |obj|
          objs[obj.id.to_s] = obj
        end
        
        results.each do |r|
          r['name'] = BioCatalogue::Util.display_name(objs[r['id']], false)
        end
        
        return results
      end
      
      # ======================

    
      # Returns:
      #   [ conditions, joins ] for use in an ActiveRecord .find method (or .paginate).
      # TODO: implement use of the search_query, so you can search within Annotations too!
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
        
        annotation_ids_for_annotatables = { }
        annotation_ids_for_sources = { }
        
        unless filters.blank?
          filters.each do |filter_type, filter_values|
            unless filter_values.blank?
              case filter_type
                when :attrib
                  conditions[:attribute_id] = filter_values
                when :as
                  annotation_ids_for_annotatables[filter_type] = get_annotation_ids_with_annotatables("Service", filter_values)
                when :asd
                  annotation_ids_for_annotatables[filter_type] = get_annotation_ids_with_annotatables("ServiceDeployment", filter_values)
                when :asp
                  annotation_ids_for_annotatables[filter_type] = get_annotation_ids_with_annotatables("ServiceProvider", filter_values)
                when :ars
                  annotation_ids_for_annotatables[filter_type] = get_annotation_ids_with_annotatables("RestService", filter_values)
                when :ass
                  annotation_ids_for_annotatables[filter_type] = get_annotation_ids_with_annotatables("SoapService", filter_values)
                when :asop
                  annotation_ids_for_annotatables[filter_type] = get_annotation_ids_with_annotatables("SoapOperation", filter_values)
                when :asin
                  annotation_ids_for_annotatables[filter_type] = get_annotation_ids_with_annotatables("SoapInput", filter_values)
                when :asout
                  annotation_ids_for_annotatables[filter_type] = get_annotation_ids_with_annotatables("SoapOutput", filter_values)
                when :soa
                  annotation_ids_for_sources[filter_type] = get_annotation_ids_with_sources("Agent", filter_values)
                when :sor
                  annotation_ids_for_sources[filter_type] = get_annotation_ids_with_sources("Registry", filter_values)
                when :sosp
                  annotation_ids_for_sources[filter_type] = get_annotation_ids_with_sources("ServiceProvider", filter_values)
                when :sou
                  annotation_ids_for_sources[filter_type] = get_annotation_ids_with_sources("User", filter_values)
                when :arm
                  annotation_ids_for_annotatables[filter_type] = get_annotation_ids_with_annotatables("RestMethod", filter_values)
                when :arp
                  annotation_ids_for_annotatables[filter_type] = get_annotation_ids_with_annotatables("RestParameter", filter_values)
                when :arr
                  annotation_ids_for_annotatables[filter_type] = get_annotation_ids_with_annotatables("RestRepresentation", filter_values)
                when :arres
                  annotation_ids_for_annotatables[filter_type] = get_annotation_ids_with_annotatables("RestResource", filter_values)
              end
            end
          end
        end
        
#        annotation_ids_for_annotatables.each do |k,v| 
#          Util.say "*** annotation_ids found for annotatables filter '#{k.to_s}' = #{v.inspect}" 
#        end
#        
#        annotation_ids_for_sources.each do |k,v| 
#          Util.say "*** annotation_ids found for sources filter '#{k.to_s}' = #{v.inspect}" 
#        end
        
        # Need to go through the various annotation IDs found for the different criterion 
        # and add to the conditions collection (if common ones are found).
        
        # The logic is as follows:
        # - The IDs found between annotatables should be OR'ed
        # - The IDs found between sources should be OR'ed
        # - The IDs between the two collections above should be AND'ed 
        
        # This will hold the two collections.
        # ie: [ [ IDs from annotatables ], [ IDs from sources ] ]
        annotation_ids = [ ]
        
        annotation_ids[0] = annotation_ids_for_annotatables.values.flatten.uniq
        annotation_ids[1] = annotation_ids_for_sources.values.flatten.uniq
        
        # To carry out this process properly, we set a dummy value of 0 to any array where relevant filters were specified but no matches were found.
        annotation_ids[0] = [ 0 ] if annotation_ids[0].empty? and !annotation_ids_for_annotatables.keys.empty?
        annotation_ids[1] = [ 0 ] if annotation_ids[1].empty? and !annotation_ids_for_sources.keys.empty?
        
        final_annotation_ids = if !annotation_ids_for_annotatables.keys.empty? and !annotation_ids_for_sources.empty?
          annotation_ids[0] & annotation_ids[1]
        elsif !annotation_ids_for_annotatables.keys.empty?
          annotation_ids[0]
        elsif !annotation_ids_for_sources.empty?
          annotation_ids[1]
        else
          nil
        end
        
#        Util.say "*** final_annotation_ids (after combining all annotation IDs found) = #{final_annotation_ids.inspect}"
        
        unless final_annotation_ids.nil?
          # Remove the dummy value of 0 in case it is in there
          final_annotation_ids.delete(0)
          
          # If a filter that relies on annotation IDs was specified but no annotations were found then no annotations should be returned
          final_annotation_ids = [ -1 ] if final_annotation_ids.blank? and (!annotation_ids_for_annotatables.keys.empty? or !annotation_ids_for_sources.empty?)
          
#          Util.say "*** final_annotation_ids (after cleanup) = #{final_annotation_ids.inspect}"
          
          conditions[:id] = final_annotation_ids unless final_annotation_ids.blank?
        end
        
        return [ conditions, joins ]
      end
      
      
      protected
      
      
      def self.get_annotation_ids_with_annotatables(annotatable_type, annotatable_ids)
        # NOTE: this query has only been tested to work with MySQL
        sql = [ "SELECT annotations.id
                FROM annotations 
                WHERE annotations.annotatable_type = ?  AND annotations.annotatable_id IN (?)",
                annotatable_type, annotatable_ids ]
        
        results = ActiveRecord::Base.connection.select_all(ActiveRecord::Base.send(:sanitize_sql, sql))
        
        return results.map{|r| r['id'].to_i}.uniq
      end
      
      def self.get_annotation_ids_with_sources(source_type, source_ids)
        # NOTE: this query has only been tested to work with MySQL
        sql = [ "SELECT annotations.id
                FROM annotations 
                WHERE annotations.source_type = ?  AND annotations.source_id IN (?)",
                source_type, source_ids ]
        
        results = ActiveRecord::Base.connection.select_all(ActiveRecord::Base.send(:sanitize_sql, sql))
        
        return results.map{|r| r['id'].to_i}.uniq
      end
      
    end
  end
end