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
          "symbol" => BioCatalogue::Api.uri_for_path("/assets/#{status.symbol_filename}"),
          "small_symbol" => BioCatalogue::Api.uri_for_path("/assets/#{status.small_symbol_filename}"),
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
      
      def self.index(name, params, collection, more={})
        has_filter = BioCatalogue::Filtering::FILTER_GROUPS.include?(name.to_sym)
        
        if name=='search'
          total_pages = (collection.size / params[:per_page].to_f).ceil
          total_entries = collection.size
          
          has_filter = true
        elsif name=='tags'
          total_pages = more[:total_pages]
          total_entries = more[:total_tags_count]
        else
          total_pages = collection.total_pages
          total_entries = collection.total_entries
        end
        
        if name=='tags'
          results = self.tags_collection(collection)
        else
          results = self.collection(collection)
        end
        
        data = {
          name => {
            "search_query" => has_filter ? params[:query] : nil,
            "current_page" => params[:page],
            "per_page" => params[:per_page],
            "pages" => total_pages, 
            "total" => total_entries,
            "results" => results
          }
        }
        
        if !params[:sort_by].blank? && !params[:sort_order].blank?
          data[name]["sort_by"] = params[:sort_by]
          data[name]["sort_order"] = params[:sort_order]
        end
                
        return data
      end
      
      def self.collection(collection, make_inline=true)
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
            "title" => "The BioCatalogue",
            "version" => BioCatalogue::VERSION,
            "api_version" => BioCatalogue::API_VERSION,
            "resource_type" => "BioCatalogue",
            "documentation" => {
              "resource" => "http://apidocs.biocatalogue.org",
              "description" => "Documentation for the BioCatalogue APIs"
            },
            "collections" => [
              self.api_endpoint_item('agents', 'Agents', 'Agents index'),
              self.api_endpoint_item('annotation_attributes', 'AnnotationAttributes', 'Annotation attributes index'),
              self.api_endpoint_item('annotations', 'Annotations', 'Annotations index'),
              self.api_endpoint_item('categories', 'Categories', 'Categories index'),
              self.api_endpoint_item('registries', 'Registries', 'Registries index'),
              self.api_endpoint_item('rest_methods', 'RestMethods', 'REST Methods index'),
              self.api_endpoint_item('rest_resources', 'RestResources', 'REST Resources index'),
              self.api_endpoint_item('rest_services', 'RestServices', 'REST Services index'),
              self.api_endpoint_item('search', 'Search', 'Search everything in the BioCatalogue'),
              self.api_endpoint_item('service_providers', 'ServiceProviders', 'Service providers index'),
              self.api_endpoint_item('services', 'Services', 'Services index'),
              self.api_endpoint_item('soap_operations', 'SoapOperations', 'Soap operations index'),
              self.api_endpoint_item('soap_services', 'SoapServices', 'SOAP Services index'),
              self.api_endpoint_item('tags', 'Tags', 'Tags index'),
              self.api_endpoint_item('test_results', 'TestResults', 'Test results index'),
              self.api_endpoint_item('users', 'Users', 'Users index'),
              {
                "filters" => [
                  self.api_endpoint_item('annotations', 'Filters', 'Filters for the annotations index', "annotations/filters"),
                  self.api_endpoint_item('rest_methods', 'Filters', 'Filters for the REST methods index', "rest_methods/filters"),
                  self.api_endpoint_item('services', 'Filters', 'Filters for the services index', "services/filters"),
                  self.api_endpoint_item('soap_operations', 'Filters', 'Filters for the SOAP operations index', "soap_operations/filters")
                ]
              }
            ]
          } 
        }
      end # self.api_endpoint
      
      # ========================================
      
      def self.tags_collection(collection, make_inline=true)
        make_inline = true unless make_inline.class.name =~ /TrueClass|FalseClass/
        
        list = []
        collection.each { |tag| list << self.tag(tag['name'], tag['label'], tag['count'], make_inline) }
        
        return list
      end # self.tags_collection
      
      def self.tag(tag_name, tag_label, total_items_count, make_inline=false)
        data = {
          "tag" => {
            "name" => tag_name,
            "display_name" => tag_label
          }
        }
        
        data["tag"]["total_items_count"] = total_items_count if total_items_count
        
        unless make_inline
          return data
        else
          return data["tag"]
        end
      end # self.tag
      
      # ========================================
      
      def self.wsdl_locations(locations)
        list = []
        locations.each { |location| list << location }
        
        return { "wsdl_locations" => list }
      end # self.wsdl_locations
            
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
              "url_value" => filter['id'],
              "count" => filter['count'].to_i
            }
          }
          
          data["filter"]["filters"] = self.filters(filter['children']) if filter['children']
          
          list << data
        end
        
        return list
      end # self.filter
      
  private # ========================================
      
      def self.api_endpoint_item(resource, resource_type, description, resource_uri=nil)
        if resource_uri.blank?
          resource_uri = self.uri_for(resource)
        else
          resource_uri = self.uri_for(resource_uri)
        end
        
        data = {
          "#{resource}" => {
            "resource" => "#{resource_uri}",
            "description" => "#{description}"
          }
        }
        
        data["#{resource}"]["resource_type"] = "#{resource_type}" if resource_type
        
        return data
      end # self.api_endpoint_item
          
      def self.uri_for(collection)
        BioCatalogue::Api.uri_for_collection(collection)
      end # self.uri_for
      
    end
  end
end