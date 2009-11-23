# BioCatalogue: lib/bio_catalogue/mapper.rb
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# Helper module to provide mapping functionality for models etc.
# E.g.: to map a given SoapOperation's ID to it's ancestor Service ID.

# NOTE that these mappings are from a search point of view.

module BioCatalogue
  module Mapper
    
    SERVICE_TYPE_ROOT_MODELS = [ SoapService, RestService ].freeze
    
    SERVICE_STRUCTURE_MODELS = [ Service, ServiceVersion, ServiceDeployment,
                                 SoapService, SoapOperation, SoapInput, SoapOutput,
                                 RestService, RestResource, RestMethod, RestParameter, RestRepresentation, RestMethodParameter, RestMethodRepresentation ].freeze
    
    SOAP_SERVICE_STRUCTURE_MODELS = [ SoapService, SoapOperation, SoapInput, SoapOutput, ].freeze
    
    REST_SERVICE_STRUCTURE_MODELS = [ RestService, RestResource, RestMethod, RestParameter, RestRepresentation, RestMethodParameter, RestMethodRepresentation ].freeze
    
    # This is used to define what models can't be mapped to other models.
    @@not_mappable = {
      "ServiceProvider" => SERVICE_STRUCTURE_MODELS.collect {|s| s.name } + [ "User", "Registry" ],
      "User" => SERVICE_STRUCTURE_MODELS.collect {|s| s.name } + [ "ServiceProvider", "Registry" ],
      "Registry" => SERVICE_STRUCTURE_MODELS.collect {|s| s.name } + [ "ServiceProvider", "User" ]
    }.freeze
    
    # ===============
    # Caching helpers
    # ---------------

    def self.generate_cache_key(map_from, map_to)
      "#{map_from}/#{map_to}"
    end

    # ===============

    def self.compound_id_for(model_name, model_id)
      return "" if model_name.blank? or model_id.nil?
      return "#{model_name}:#{model_id.to_s}"
    end
    
    def self.compound_id_for_model_object(obj)
      return "" unless obj.kind_of?(ActiveRecord::Base)
      return "#{obj.class.name}:#{obj.id.to_s}"
    end
    
    # Given a compound ID (eg: "ServiceDeployment:3"), this method will split it into it's constituent parts.
    # Returns an array with the first value being the model name (or model class if _constantize_model_name_ is set to true)
    # and the second part the integer ID of the object.
    def self.split_compound_id(compound_id, constantize_model_name=false)
      return [ ] if compound_id.nil?
      
      model = nil
      id = nil
      
      model, id = compound_id.split(':')
      
      model = model.constantize if constantize_model_name
      
      id = id.to_i
      
      return [ model, id ]
    end
    
    # Given a list of IDs, returns back the model objects as specified by model_name.
    # This respects the ordering in the items_ids list.
    def self.item_ids_to_model_objects(item_ids, model_name)
      items = [ ]
    
      return items if item_ids.blank? or model_name.blank?
      
      model = model_name.classify.constantize
      
      items_temp = model.find(:all, :conditions => { :id => item_ids })
      
      # Order back to the same ordering as the initial item_ids list
      item_ids.each do |i|
        items.concat items_temp.select{|x| x.id == i }
      end
      
      return items
    end
    
    def self.compound_ids_to_model_objects(compound_ids)
      items = [ ]
    
      return items if compound_ids.blank?
      
      compound_ids.each do |c|
        model, id = Mapper.split_compound_id(c, true)
        item = model.find(:first, :conditions => { :id => id })
        items << item unless item.nil?
      end
      
      return items
    end
    
    # Processes a list of compound IDs (format: "{model_name}:{id}") to build a list of 
    # the IDs of the *associated* objects of the model_name specified.
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
    
    # E.g.: if the compound_id is "SoapOperation:203", then the ancestor Service ID will be returned, if model_name is specified as "Service".
    # NOTE: only works for getting associated Services OR the annotatable of an Annotation.
    def self.map_compound_id_to_associated_model_object_id(compound_id, model_name)
      return nil if compound_id.blank? or model_name.blank?
      
      source_model_name, source_id = split_compound_id(compound_id)
      
      # First check if we can do this mapping...
      return nil if @@not_mappable[model_name] and @@not_mappable[model_name].include?(source_model_name)
      
      associated_model_object_id = nil
      
      if source_model_name == model_name
        associated_model_object_id = source_id
      else
        cache_key = generate_cache_key(compound_id, model_name)
        
        # Try and get it from the cache...
        cached_value = Rails.cache.read(cache_key)
        
        if cached_value.nil?
          # It's not in the cache so get the value and store it in the cache...
          
          new_value = nil
          
          # Special case for Annotations:
          if source_model_name == "Annotation"
            ann = Annotation.find(source_id)
            new_value = ann.annotatable_id if ann.annotatable_type == model_name
          end
          
          # If nothing was found yet, carry on...
          if new_value.nil?
            new_value = case model_name.to_s
              when "Service"
                Mapper.get_ancestor_service_id(source_model_name, source_id)
            end
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
    
    # A convenience method that uses the Mapper#map_compound_id_to_associated_model_object_id
    # to directly return the relevant associated object (or nil).
    # NOTE: currently only works for Service as the 'model_name'
    def self.map_object_to_associated_model_object(object, model_name)
      model_name.constantize.find_by_id(map_compound_id_to_associated_model_object_id(compound_id_for_model_object(object), model_name))
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