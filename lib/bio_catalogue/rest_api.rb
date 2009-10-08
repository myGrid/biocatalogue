# BioCatalogue: lib/bio_catalogue/rest_api.rb
#
# Copyright (c) 2008-2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# Module to abstract out any specific processing for the REST XML/JSON/etc API

module BioCatalogue
  module RestApi
    
    module Builder
      
      def self.root_attributes
        return { "xmlns" => "http://www.biocatalogue.org/2009/xml/rest",
                 "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance",
                 "xsi:schemaLocation" => "http://www.biocatalogue.org/2009/xml/rest " + URI.join(SITE_BASE_HOST, "2009/xml/rest/schema-v1.xsd").to_s }
      end
      
    end
    
    module Resources
      
      def self.uri_for_collection(resource_name, *args)
        options = args.extract_options!
        # defaults:
        options.reverse_merge!(:params => nil)        
        
        uri = ""
        
        unless resource_name.blank?
          uri = URI.join(SITE_BASE_HOST, resource_name).to_s
          uri = append_params(uri, options[:params]) unless options[:params].blank?
        end
        
        return uri
      end
      
      def self.uri_for_object(resource_obj, *args)
        options = args.extract_options!
        # defaults:
        options.reverse_merge!(:params => nil,
                               :sub_path => nil)
                               
        uri = ""
        
        unless resource_obj.nil?
          resource_part = "#{resource_obj.class.name.pluralize.underscore}/#{resource_obj.id}"
          unless options[:sub_path].blank?
            sub_path = options[:sub_path]
            sub_path = "/#{sub_path}" unless sub_path.starts_with?('/')
            resource_part += sub_path
          end
          uri = URI.join(SITE_BASE_HOST, resource_part).to_s
          uri = append_params(uri, options[:params]) unless options[:params].blank?
        end
        
        return uri
      end
      
      protected
      
      def self.append_params(uri, params)
        # Remove the special params
        new_params = BioCatalogue::Util.remove_rails_special_params_from(params)
        return (new_params.blank? ? uri : "#{uri}?#{new_params.to_query}")
      end
      
    end
    
  end
end