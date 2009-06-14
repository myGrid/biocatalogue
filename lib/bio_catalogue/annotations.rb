# BioCatalogue: lib/bio_catalogue/stats.rb
#
# Copyright (c) 2008, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# A helper module for annotations/metadata related functionality, that works on top of the Annotations plugin.

module BioCatalogue
  module Annotations
    
    # Returns back a list of the different metadata sources that are possible in the system
    # (returned as symbols).
    # 
    # This should be in sync with the groups of metadata returned by the metadata_counts_for_service
    # below (excluding :total, ofcourse).
    def self.metadata_sources
      [ :users, :registries, :providers ]
    end
    
    # Returns the number of annotations on a service by a specified source (or "all" for all sources).
    #
    # This takes into account the entire service structure (ie: service container, 
    # service versions, service deployments, and the entire substructure of the service version instances). 
    #
    # NOTE: this method ONLY takes into account annotations stored through the annotations plugin.
    def self.total_number_of_annotations_for_service(service, source_type="all")
      return 0 if service.nil?
      
      count = 0
      
      count += service.count_annotations_by(source_type)
      
      service.service_deployments.each do |s_d|
        count += s_d.count_annotations_by(source_type)
      end
      
      service.service_versions.each do |s_v|
        count += s_v.count_annotations_by(source_type)
        count += s_v.service_versionified.total_annotations_count(source_type)
      end
      
      return count
    end
    
    # Returns a hash with all the counts of the metadata pieces on a service,
    # grouped by the types of sources, as well as the total number of metadata pieces.
    #
    # This takes into account the entire service structure (ie: service container, 
    # service versions, service deployments, and the entire substructure of the service version instances). 
    #
    # NOTE (1): the notion of "metadata pieces" here is the combination of metadata stored in the database
    # (often gained from the service description docs) AND metadata stored as annotation through the Annotations plugin.
    # NOTE (2): to the user, "metadata pieces" and "annotations" are synonymous, but in the sytem these are different
    # but related concepts.
    #
    # The following keys are available in the hash (see metadata_sources method above):
    #  :total       - the total number of metadata pieces on this service (incl those in the db tables AND the Annotations plugin).
    #  :users       - the total number of annotations provided by users.
    #  :registries  - the total number of annotations that came from other registries.
    #  :providers   - the total number of annotations that came from the service providers (eg: from the service description docs).
    def self.metadata_counts_for_service(service, recalculate=false)
      counts = { }
      
      return counts if service.nil?
      
      cache_key = CacheHelper.cache_key_for(:metadata_counts_for_service, service)
      
      if recalculate
        Rails.cache.delete(cache_key)
      end
      
      # Try and get it from the cache...
      cached_counts = Rails.cache.read(cache_key)
      
      if cached_counts.nil?
        # It's not in the cache so get the value and store it in the cache...
        
        # :users
        # Made up of annotations, as well as some metadata stored in the db...
        
        users_count = total_number_of_annotations_for_service(service, "User")
        
        service.service_versions.each do |s_v|
          # Metadata of RestServices comes from users
          users_count += s_v.service_versionified.total_db_metadata_fields_count if s_v.service_versionified_type == "RestService"
        end
        
        counts[:users] = users_count
        
        # :registries
        counts[:registries] = total_number_of_annotations_for_service(service, "Registry")
        
        # :providers
        # Made up of annotations, as well as some metadata stored in the db...
        
        providers_count = total_number_of_annotations_for_service(service, "ServiceProvider")
        
        # For now only the metadata of SoapServices comes from a service description doc (ie: from a service provider)
        service.service_versions.each do |s_v|
          providers_count += s_v.service_versionified.total_db_metadata_fields_count if s_v.service_versionified_type == "SoapService"
        end
        
        counts[:providers] = providers_count
        
        # :total
        counts[:total] = counts.values.sum
        
        # Finally write it to the cache...
        Rails.cache.write(cache_key, counts, :expires_in => METADATA_COUNTS_DATA_CACHE_TIME)
      else
        counts = cached_counts
      end
      
      return counts
    end
    
    # Gets all the name annotations for a specified service
    def self.all_name_annotations_for_service(service)
      annotations = [ ]
      
      annotations.concat(service.annotations_with_attribute("name"))
      
      service.service_deployments.each do |s_d|
        annotations.concat(s_d.annotations_with_attribute("name"))
      end
      
      service.service_versions.each do |s_v|
        annotations.concat(s_v.annotations_with_attribute("name"))
        annotations.concat(s_v.service_versionified.annotations_with_attribute("name"))
      end
      
      return annotations
    end
    
    # This method gets the tag annotation objects for the specific annotatable object.
    # It applies special finder rules. E.g: for a Service, it also gets the tags for it's
    # ServiceDeployment, ServiceVersion and service versionified objects.
    def self.get_tag_annotations_for_annotatable(annotatable)
      tag_annotations = [ ]
      
      tag_annotations = annotatable.annotations_with_attribute("tag")
      
      # Any specific processing...
      if annotatable.class.name == "Service"
        annotatable.service_deployments.each do |s_d|
          tag_annotations.concat(s_d.annotations_with_attribute("tag"))
        end
        
        annotatable.service_versions.each do |s_v|
          tag_annotations.concat(s_v.annotations_with_attribute("tag"))
          tag_annotations.concat(s_v.service_versionified.annotations_with_attribute("tag"))
        end
      end
    
      return tag_annotations
    end
    
    # This utility method takes a hash of annotations data and does some preprocessing on them.
    # This is at a higher level than the processing done by the Annotations plugin,
    # and is mainly just to rearrange/restructure the data in the annotations_data hash so that
    # it is in a more appropriate format to be used when creating annotations out of it.
    # (e.g.: when used in the create_annotations method).
    #
    # Fields with a nil value will be removed.
    #
    # The following attribute specific processing is applied:
    #   - for :tags -
    #       it will transform { :tags => "test1, test2, test3" } into { :tag => [ "test1", "test2", "test3" ] } 
    #
    # NOTE: for preprocessing to work on attributes, the keys MUST be symbols, NOT strings.
    #       Keys with strings will still be returned back but no preprocessing will occur on them.
    def self.preprocess_annotations_data(annotations_data)
      # Remove fields that have a nil value
      annotations_data.keys.each do |attrib|
        annotations_data.delete(attrib) if annotations_data.has_key?(attrib) && annotations_data[attrib].nil?
      end
      
      # :tags to :tag
      if annotations_data.has_key?(:tags)
        annotations_data[:tag] = annotations_data[:tags].split(',').compact.map{|x| x.strip}.reject{|x| x == ""}
        annotations_data.delete(:tags)
      end
      
      # :categories to :category
      if annotations_data.has_key?(:categories)
        annotations_data[:category] = annotations_data[:categories].split(',').compact.map{|x| x.strip}.reject{|x| x == ""}
        annotations_data.delete(:categories)
      end
      
      # :names to :name
      if annotations_data.has_key?(:names)
        annotations_data[:name] = annotations_data[:names].split(',').compact.map{|x| x.strip}.reject{|x| x == ""}
        annotations_data.delete(:names)
      end
      
      return annotations_data
    end
    
  end
end