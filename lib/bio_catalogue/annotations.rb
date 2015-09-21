# BioCatalogue: lib/bio_catalogue/annotations.rb
#
# Copyright (c) 2009-2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# A helper module for annotations/metadata related functionality, that works on top of the Annotations plugin.

module BioCatalogue
  module Annotations
    
    # List of annotation attributes that are considered "known" or important in the system
    KNOWN_ANNOTATION_ATTRIBUTES = { :services => [ "category", "tag", "description", "alternative_name", 
                                                   "example_data", "documentation_url", "cost", "license",
                                                   "contact", "format", "example_endpoint", "data_schema",
                                                   "elixir_description" ].freeze,
                                    :providers => [ "display_name", "alternative_name", "website" ].freeze }.freeze
    
    # Returns back a list of the different metadata sources that are possible in the system
    # (returned as symbols).
    # 
    # This should be in sync with the groups of metadata returned by the metadata_counts_for_service
    # below (excluding :all).
    def self.metadata_sources
      [ :users, :registries, :providers ]
    end
    
    # Returns the number of annotations on a service by a specified source (or "all" for all sources).
    #
    # This takes into account the entire service structure (ie: service container, 
    # service versions, service deployments, and the entire substructure of the service version instances). 
    #
    # IMPORTANT NOTE: this method ONLY takes into account annotations stored through the annotations plugin,
    # so doesn't include the provider/submitter metadata directly in the database tables.
    # Use #metadata_counts_for_service# to get counts that include the provider/submitter metadata directly in the database tables.
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
    #  :all         - the total number of metadata pieces on this service (incl those in the db tables AND the Annotations plugin).
    #  :users       - the total number of annotations provided by users.
    #  :registries  - the total number of annotations that came from other registries.
    #  :providers   - the total number of annotations that came from the service providers (eg: from the service description docs).
    def self.metadata_counts_for_service(service, recalculate=false)
      counts = { }
      
      return counts if service.nil?
      
      cache_key = CacheHelper.cache_key_for(:metadata_counts_for_service, service.id)
      
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
        service.service_version_instances_by_type("SoapService").each do |si|
          providers_count += si.total_db_metadata_fields_count
        end
        
        counts[:providers] = providers_count
        
        # :all
        counts[:all] = counts.values.sum
        
        # Finally write it to the cache...
        Rails.cache.write(cache_key, counts, :expires_in => METADATA_COUNTS_DATA_CACHE_TIME)
      else
        counts = cached_counts
      end
      
      return counts
    end
    
    # Gets the annotations on a Service and its ServiceVersions, ServiceDeployments 
    # and service version instances (eg SoapService and/or RestService)
    def self.annotations_for_service(service)
      annotations = [ ]
      
      annotations.concat(service.annotations)
      
      service.service_deployments.each do |s_d|
        annotations.concat(s_d.annotations)
      end
      
      service.service_versions.each do |s_v|
        annotations.concat(s_v.annotations)
        annotations.concat(s_v.service_versionified.annotations)
      end
      
      return annotations
    end
    
    # Gets the annotations (of a specified attribute) on a Service and its 
    # ServiceVersions, ServiceDeployments and service version instances (eg SoapService and/or RestService)
    def self.annotations_for_service_by_attribute(service, attribute)
      annotations = [ ]
      
      annotations.concat(service.annotations_with_attribute(attribute, true))
      
      service.service_deployments.each do |s_d|
        annotations.concat(s_d.annotations_with_attribute(attribute, true))
      end
      
      service.service_versions.each do |s_v|
        annotations.concat(s_v.annotations_with_attribute(attribute, true))
        annotations.concat(s_v.service_versionified.annotations_with_attribute(attribute, true))
      end
      
      return annotations
    end
    
    # This method gets the tag annotation objects for the specific annotatable object.
    # It applies special finder rules. E.g: for a Service, it also gets the tags for it's
    # ServiceDeployments, ServiceVersions and service version instances.
    def self.get_tag_annotations_for_annotatable(annotatable)
      tag_annotations = [ ]
      
      if annotatable.is_a? Service
        tag_annotations = annotations_for_service_by_attribute(annotatable, "tag")
      else
        tag_annotations = annotatable.annotations_with_attribute("tag", true)
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
    #   - for :tags, 'tags', :categories, 'categories', :alternative_names, 'alternative_names' -
    #       it will transform { :tags => "test1, test2, test3" } into { :tag => [ "test1", "test2", "test3" ] } 
    def self.preprocess_annotations_data(annotations_data)
      # Remove fields that have a nil value
      annotations_data.keys.each do |attrib|
        annotations_data.delete(attrib) if annotations_data.has_key?(attrib) && annotations_data[attrib].nil?
      end
      
      transform_attribute_for_annotations_data(:tags, :tag, annotations_data) # :tags to :tags
      transform_attribute_for_annotations_data('tags', 'tag', annotations_data) # 'tags' to 'tags'

      transform_attribute_for_annotations_data(:categories, :category, annotations_data) # :categories to :category
      transform_attribute_for_annotations_data('categories', 'category', annotations_data) # 'categories' to 'category'

      transform_attribute_for_annotations_data(:alternative_names, :alternative_name, annotations_data) # :alternative_names to :alternative_name
      transform_attribute_for_annotations_data('alternative_names', 'alternative_name', annotations_data) # 'alternative_names' to 'alternative_name'
      
      return annotations_data
    end
    
    # LEGACY!!!
    # Helper method to get the ratings categories configuration hash for a specific model type.
    # This acts as a lookup table for ratings configuration to models and allows us to maintain different
    # ratings configurations for different models.
    def self.get_ratings_categories_config_for_model(model_name)
      ratings_config = { }
      
      case model_name.to_s
        when "Service", "SoapService", "RestService"  
          ratings_config = SERVICE_RATINGS_CATEGORIES
      end
      
      return ratings_config
    end
    
    # Given a list of Annotations, this method will return hash of Annotations grouped by attribute name.
    def self.group_by_attribute_names(annotations)
      grouped = { }
      
      return grouped if annotations.blank?
      
      annotations.each do |ann|
        
        if grouped.has_key?(ann.attribute_name)
          grouped[ann.attribute_name] << ann          
        else
          grouped[ann.attribute_name] = [ ann ]
        end
        
      end
      
      return grouped
    end
    
    # Create Annotations in bulk...
    #
    # Note that this is run through the annotations preprocessor so
    # attributes like "tags" and "categories" are allowed.
    #
    # Example Input:
    #
    # [ 
    #   {
    #     "resource" => "http://www.biocatalogue.org/soap_inputs/23",
    #     "annotations" => {
    #       "tag" => [ "x", "y", "z" ],
    #       "description" => "ihouh uh ouho ouh"
    #     }
    #   },
    #   {
    #     "resource" => "http://www.biocatalogue.org/soap_operations/237",
    #     "annotations" => {
    #       "tag" => [ "x", "y", "z" ],
    #       "description" => "ihouh uh ouho ouh"
    #     }
    #   } 
    # ]
    #
    # Example Output:
    #
    # [ 
    #   {
    #     "resource" => "http://www.biocatalogue.org/soap_inputs/23",
    #     "annotations" => [
    #       <<Annotation objects>>
    #     ]
    #   },
    #   {
    #     "resource" => "http://www.biocatalogue.org/soap_operations/237",
    #     "annotations" => [
    #       <<Annotation objects>>
    #     ] 
    #   } 
    # ]
    #
    # Note that the output will ONLY include the valid resources and successfully
    # created annotations.
    def self.bulk_create(annotation_groups, source)
      results = [ ]
      
      unless annotation_groups.blank?
        annotation_groups.each do |x|
          obj = BioCatalogue::Api.object_for_uri(x["resource"])
          unless obj.nil?
            # TODO: how to prevent annotations being created on objects that they shouldn't be 
            result = { }
            result["resource"] = x["resource"]
            
            if x["annotations"].blank?
              result["annotations"] = [ ]
            else
              anns = obj.create_annotations(Annotations.preprocess_annotations_data(x["annotations"]), source)
              result["annotations"] = BioCatalogue::Api::Json.collection(anns)
            end
            
            results << result
          end
        end
      end
      
      return results
    end
    
  private
  
    def self.transform_attribute_for_annotations_data(from_attr, to_attr, annotations_data)
      if annotations_data.has_key?(from_attr)
        annotations_data[from_attr] = annotations_data[from_attr].split(',') if annotations_data[from_attr].is_a?(String)
        annotations_data[to_attr] = annotations_data[from_attr].compact.map{|x| x.to_s.strip}.reject{|x| x == ""} if annotations_data[from_attr].is_a?(Array)
        annotations_data.delete(from_attr)
      end
    end
    
  end
end