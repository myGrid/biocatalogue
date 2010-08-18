# BioCatalogue: lib/bio_catalogue/json.rb
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# Module to abstract out any specific processing for the REST JSON API

module BioCatalogue
  module Api
    module Json
    
      # JSON Output Helpers
      
      # ========================================
      
      def self.monitoring_status(status)
        {
          "label" => status.label,
          "message" => status.message,
          "symbol" => BioCatalogue::Api.uri_for_path("/images/#{status.symbol_filename}"),
          "small_symbol" => BioCatalogue::Api.uri_for_path("/images/#{status.small_symbol_filename}"),
          "last_checked" => (status.last_checked ? status.last_checked.iso8601 : nil)
        }
      end # self.monitoring_status
      
      # ========================================
      
      def self.location(country, city="")
        country_code = CountryCodes.code(country)
        
        {
          "city" => city,
          "country" => country,
          "country_code" => country_code,
          "flag" => BioCatalogue::Api.uri_for_path(BioCatalogue::Resource.flag_icon_path(country_code))
        }
      end # self.location
      
      # ========================================
      
      def self.index(name, params, collection, make_inline)
        has_filter = BioCatalogue::Filtering::FILTER_GROUPS.include?(name.to_sym) # FIXME
        
        if name=='search'
          total_pages = (collection.size / params[:per_page].to_f).ceil
          total_entries = collection.size
          
          has_filter = true
        else
          total_pages = collection.total_pages
          total_entries = collection.total_entries
        end
        
        data = {
          name => {
            "search_query" => has_filter ? params[:query] : nil,
            "current_page" => params[:page],
            "per_page" => params[:per_page],
            "pages" => total_pages, 
            "total" => total_entries,
            "results" => self.collection(collection, make_inline)
          }
        }
        
        if !params[:sort_by].blank? && !params[:sort_order].blank?
          data[name]["sort_by"] = params[:sort_by]
          data[name]["sort_order"] = params[:sort_order]
        end
                
        return data
      end
      
      def self.collection(collection, make_inline)
        make_inline = true unless make_inline.class.name =~ /TrueClass|FalseClass/
        
        list = []
          
        collection.each do |item|
          if make_inline
            list << JSON(item.to_inline_json)
          else
            list << JSON(item.to_json)
          end
        end
        
        return list
      end # self.collection
      
      # ========================================
          
      def self.api_endpoint
        {
          "biocatalogue" => {
            "documentation" => {
              "resource" => "http://apidocs.biocatalogue.org",
              "description" => "Documentation for the BioCatalogue APIs"
            },

            "collections" => [
              self.generate_hash('agents', 'Agents', self.uri_for("agents"), 'Agents index'),
              self.generate_hash('annotation_attributes', 'AnnotationAttributes', self.uri_for("annotation_attributes"), 'Annotation attributes index'),
              self.generate_hash('annotations', 'Annotations', self.uri_for("annotations"), 'Annotations index'),
              self.generate_hash('categories', 'Categories', self.uri_for("categories"), 'Categories index'),
              self.generate_hash('registries', 'Registries', self.uri_for("registries"), 'Registries index'),
              self.generate_hash('rest_methods', 'RestMethods', self.uri_for("rest_methods"), 'REST Methods index'),
              self.generate_hash('rest_resources', 'RestResources', self.uri_for("rest_resources"), 'REST Resources index'),
              self.generate_hash('rest_services', 'RestServices', self.uri_for("rest_services"), 'REST Services index'),
              self.generate_hash('search', 'Search', self.uri_for("search"), 'Search everything in the BioCatalogue'),
              self.generate_hash('services', 'Services', self.uri_for("services"), 'Services index'),
              self.generate_hash('service_providers', 'ServiceProviders', self.uri_for("service_providers"), 'Service providers index'),
              self.generate_hash('soap_operations', 'SoapOperations', self.uri_for("soap_operations"), 'Soap operations index'),
              self.generate_hash('soap_services', 'SoapServices', self.uri_for("soap_services"), 'SOAP Services index'),
              self.generate_hash('tags', 'Tags', self.uri_for("tags"), 'Tags index'),
              self.generate_hash('test_results', 'TestResults', self.uri_for("test_results"), 'Test results index'),
              self.generate_hash('users', 'Users', self.uri_for("users"), 'Users index'),
              {
                "filters" => [
                  self.generate_hash('services', 'Filters', self.uri_for("services/filters"), 'Filters for the services index'),
                  self.generate_hash('soap_operations', 'Filters', self.uri_for("soap_operations/filters"), 'Filters for the SOAP operations index'),
                  self.generate_hash('annotations', 'Filters', self.uri_for("annotations/filters"), 'Filters for the annotations index')
                ]
              }
            ]
          } 
        }
      end # self.api_endpoint
      
      # ========================================
      
      def self.tags_collection(collection)
        list = []
        collection.each { |tag| list << self.tag(tag['name'], tag['count']) }
        return list
      end # self.tags_collection
      
      def self.tag(tag_name, total_items_count)
        data = {
          "tag" => {
            "name" => tag_name,
            "display_name" => BioCatalogue::Tags.split_ontology_term_uri(tag_name)[1]
          }
        }
        
        data["tag"]["total_items_count"] = total_items_count if total_items_count
        return data
      end # self.tag
      
      # ========================================
      
      def self.wsdl_locations(locations)
        list = []
        locations.each { |location| list << self.wsdl_location(location) }
        
        return list
      end # self.wsdl_locations
      
      def self.wsdl_location(location)
        { "wsdl_location" => location }
      end
      
      # ========================================
      
      def self.filter_groups(groups)
        list = []
        
        groups.each do |group|
          list << { 
            "group" => {
              "name" => group.name,
              "filter_types" => self.filter_types(group.filter_types)
            }
          }
        end
        
        return list
      end # self.filter_groups

      def self.filter_types(filter_types)
        list = []

        filter_types.each do |filter_type|
          list << {
            "filter_type" => {
              "url_key" => filter_type.key.to_s,
              "name" => filter_type.name,
              "description" => filter_type.description,
              "filters" => self.filters(filter_type.filters)
            }
          }
        end

        return list
      end # self.filter_types
      
      def self.filters(filters)
        list = []

        filters.each do |filter|
          data = {
            "filter" => {
              "name" => filter['name'],
              "id" => filter['id'],
              "count" => filter['count'].to_i
            }
          }
          
          data["filter"]["filters"] = self.filters(filter['children']) if filter['children']
          
          list << data
        end
        
        return list
      end # self.filter
      
  private # ========================================
      
      def self.generate_hash(resource, resource_type, resource_uri, description)
        data = {
          "#{resource}" => {
            "resource" => "#{resource_uri}",
            "description" => "#{description}"
          }
        }
        
        data["#{resource}"]["resource_type"] = "#{resource_type}" if resource_type
        
        return data
      end # self.generate_hash
          
      def self.uri_for(collection)
        BioCatalogue::Api.uri_for_collection(collection)
      end # self.uri_for
      
    end
  end
end