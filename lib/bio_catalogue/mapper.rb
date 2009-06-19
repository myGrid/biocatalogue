# BioCatalogue: lib/bio_catalogue/mapper.rb
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# Helper module to provide mapping functionality for models etc.
# E.g.: to map a given SoapOperation's ID to it's ancestor Service ID.

module BioCatalogue
  module Mapper
    
    SERVICE_TYPE_ROOT_MODELS = [ SoapService, RestService ]
    
    SERVICE_STRUCTURE_MODELS = [ Service, ServiceVersion, ServiceDeployment,
                                 SoapService, SoapOperation, SoapInput, SoapOutput,
                                 RestService, RestResource, RestMethod, RestParameter, RestRepresentation, RestMethodParameter, RestMethodRepresentation ].freeze
    
    # ===============
    # Caching helpers
    # ---------------

    def self.generate_cache_key(map_from, map_to)
      "#{map_from}/#{map_to}"
    end

    # ===============
    
    # Processes a list of compound IDs (format: "{model_name}:{id}") to build a list of 
    # the IDs of the associated objects (of the model_name provided).
    #
    # E.g.: if there is "SoapOperation:203", then the ancestor Service ID will be retrieved.
    #
    # Arguments:
    # - compound_ids - Array of IDs in the compound IDs format ("{model_name}:{id}").
    # - model_name - the name of the model that the compound IDs should be mapped and processed to.
    #
    # Returns:
    #  - An Array of Integer IDs that are the IDs of the associated objects (of the model_name provided).
    def self.process_compound_ids_to_associated_model_object_ids(compound_ids, model_name)
      return [ ] if compound_ids.nil? or model_name.nil?
      
      associated_model_object_ids = [ ]
      
      compound_ids.each do |compound_id|
        processed_id = self.map_compound_id_to_associated_model_object_id(compound_id, model_name)
        associated_model_object_ids << processed_id unless processed_id.nil?
      end
      
      return associated_model_object_ids
    end
    
    # E.g.: if the compound_id is "SoapOperation:203", then the ancestor Service ID will be returned.
    def self.map_compound_id_to_associated_model_object_id(compound_id, model_name)
      associated_model_object_id = nil
      
      source_model_name, source_id = compound_id.split(':')
      
      source_id = source_id.to_i
        
      if source_model_name == model_name
        associated_model_object_id = source_id
      else
        cache_key = generate_cache_key(compound_id, model_name)
        
        # Try and get it from the cache...
        cached_value = Rails.cache.read(cache_key)
        
        if cached_value.nil?
          # It's not in the cache so get the value and store it in the cache...
          new_value = case model_name.to_s
            when "Service"
              BioCatalogue::Mapper.get_ancestor_service_id(source_model_name, source_id)
          end
          
          if new_value.blank?
            Rails.cache.write(cache_key, BioCatalogue::CacheHelper::NONE_VALUE)
          else
            new_value = new_value.to_i
            Rails.cache.write(cache_key, new_value)
            associated_model_object_id = new_value
          end
        else
          unless cached_value == BioCatalogue::CacheHelper::NONE_VALUE
            associated_model_object_id = cached_value
          end
        end
      end
      
      return associated_model_object_id
    end
    
    protected
    
    # NOTE: this is NOT cached, and hence it is not a public method.
    # Use Mapper::map_compound_id_to_associated_model_object_id
    def self.get_ancestor_service_id(source_model_name, source_id)
      case source_model_name.to_s
        when "Service"
          return source_id
        else
          return self.get_id_value_from_sql_query(self.sql_query_to_get_service_id_for_source_model_item(source_model_name, source_id))
      end
    end
    
    # Generic helper method to run a sql query and then return back the first record's "id" field.
    # The sql query provided must be in the form of an Array so it can be sanitised.
    def self.get_id_value_from_sql_query(sql)
      id_value = nil
      
      data = ActiveRecord::Base.connection.select_all(ActiveRecord::Base.send(:sanitize_sql, sql))
      
      if !data.blank? and data.first.has_key?("id")
        id_value = data.first.fetch("id")
      end
      
      return id_value
    end
    
    # NOTE: the SQL queries here have only been tested to work with MySQL 5.0.x
    def self.sql_query_to_get_service_id_for_source_model_item(source_model_name, source_id)
      sql = nil
      
      case source_model_name
        when "Service"
          sql = [ "SELECT ? AS id", source_id ]
        when "ServiceVersion"
          sql = [ "SELECT service_id AS id
                  FROM service_versions
                  WHERE service_versions.id = ?",
                  source_id ]
        when "ServiceDeployment"
          sql = [ "SELECT service_id AS id
                  FROM service_deployments
                  WHERE service_deployments.id = ?",
                  source_id ]
        when "SoapService", "RestService"
          sql = [ "SELECT service_id AS id 
                  FROM service_versions 
                  WHERE service_versions.service_versionified_type = ? AND service_versions.service_versionified_id = ?",
                  source_model_name, source_id ]
        when "SoapOperation"
          sql = [ "SELECT service_versions.service_id AS id 
                  FROM soap_operations
                  INNER JOIN soap_services ON soap_operations.soap_service_id = soap_services.id
                  INNER JOIN service_versions ON (soap_services.id = service_versions.service_versionified_id AND service_versions.service_versionified_type = 'SoapService') 
                  WHERE soap_operations.id = ?",
                  source_id ]
        when "SoapInput"
          sql = [ "SELECT service_versions.service_id AS id 
                  FROM soap_inputs
                  INNER JOIN soap_operations ON soap_inputs.soap_operation_id = soap_operations.id
                  INNER JOIN soap_services ON soap_operations.soap_service_id = soap_services.id
                  INNER JOIN service_versions ON (soap_services.id = service_versions.service_versionified_id AND service_versions.service_versionified_type = 'SoapService') 
                  WHERE soap_inputs.id = ?",
                  source_id ]
        when "SoapOutput"
          sql = [ "SELECT service_versions.service_id AS id 
                  FROM soap_outputs
                  INNER JOIN soap_operations ON soap_outputs.soap_operation_id = soap_operations.id
                  INNER JOIN soap_services ON soap_operations.soap_service_id = soap_services.id
                  INNER JOIN service_versions ON (soap_services.id = service_versions.service_versionified_id AND service_versions.service_versionified_type = 'SoapService') 
                  WHERE soap_outputs.id = ?",
                  source_id ]
        when "Annotation"
          ann = Annotation.find(source_id)
          if ann.nil?
            sql = "SELECT 'nothing'"
          else
            sql = self.sql_query_to_get_service_id_for_source_model_item(ann.annotatable_type, ann.annotatable_id)
          end
        when "User", "ServiceProvider", "Registry", "Agent"
          sql = "SELECT 'nothing'"
        else
          Rails.logger.warn "SQL for mapping #{source_model_name} objects to Services has not been implemented yet!"
          sql = "SELECT 'nothing'"
      end
      
      return sql
    end
    
  end
end