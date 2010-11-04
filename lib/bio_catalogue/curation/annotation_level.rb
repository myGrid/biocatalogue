# BioCatalogue: lib/bio_catalogue/curation/annotation_lever.rb
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# A helper module for calculating the level of annotation of a service.

# This module does a simple calculation for the level of annotation of a service.
# It assigns points for the presence of annotations for service attributes.
# In the future these attributes could be weighted. For example if a value for an 
# attribute is present, it could be weighted based on the attribute type and 
# source of the attribute value. Provider attribute values, like descriptions from
# interface documents would have a higher weighting than those from users(community). Also
# a service level description will have a higher weighting than an input or output description.

# The max number of points each service can have depends on the number of operations and
# the number of inputs and outputs that these operations have.

# The annotation level is determine as a ratio of the point obtained over the possible max


module BioCatalogue

  module Curation
    module AnnotationLevel
      
      def self.annotation_level_for_service(service)
        ((points_for_service(service).to_f/max_points_for_service(service).to_f) *100 ).to_i
      end
      
      private
      
      def self.non_provider_annotations?(parent, attr='description')
        if parent.respond_to?(:annotations)
          return true if parent.annotations.collect{|a| a if a.attribute.name.downcase == attr}.compact.count > 0 
        end
        return false
      end
      
      
      # Some annotation attributes are not used
      # in the calculation of the level of annotation
      # as they legitimately may not be available for 
      # some services.
      # For example, every service does not necessary have
      # have a publication and therefore this attribute
      # is not used in the calculation of the annotation
      # level
      def self.annotatable_attributes_for(annotatable)
        
        attrs = { 'Service'           =>  ['category', 'display_name', 'tag'],              # ['alternative_name','category', 'display_name', 'tag' ]
                  'ServiceDeployment' =>  ['contact', 'cost', ],                            # ['contact', 'cost', 'usage_condition']
                  'SoapService'       =>  ['description', 'documentation_url', 'license'],  # ['citation','description', 'documentation_url', 'license', 'publication']
                  'RestService'       =>  ['description', 'documentation_url', 'license'],  # ['citation','description', 'documentation_url', 'license', 'publication']
                  'SoapOperation'     =>  ['description'],                                  # ['alternative_name', 'description', 'tag'],
                  'SoapInput'         =>  ['description', 'example_data', 'format'],        # ['alternative_name', 'description', 'example_data', 'format', 'tag'],
                  'SoapOutput'        =>  ['description', 'example_data', 'format'],        # ['alternative_name', 'description', 'example_data', 'format', 'tag'],
                  'ServiceProvider'   =>  ['contact', 'description','display_name']         # ['alternative_name', 'contact', 'description','display_name', 'website']
                  }
        return attrs[annotatable.class.name]
      end
      
      def self.service_annotatables(service)
        service_instance  = service.latest_version.service_versionified
        annotatables      = [service]
        annotatables.concat(service.service_deployments)
        annotatables << service_instance
        if service_instance.respond_to?(:soap_operations)
          annotatables.concat(service_instance.soap_operations) 
          service_instance.soap_operations.each do |op|
            annotatables.concat(op.soap_inputs)
            annotatables.concat(op.soap_outputs)
          end
        end
        if service_instance.respond_to?(:rest_resources)
          annotatables.concat(service_instance.rest_resources) 
        end
        return annotatables
      end
      
      def self.max_points_for_annotatable(annotatable)
        unless annotatable_attributes_for(annotatable).nil?
          if annotatable.respond_to?(:description)
            return annotatable_attributes_for(annotatable).count + 1
          end
          return annotatable_attributes_for(annotatable).count
        end
        return 1
      end
      
      def self.points_for_annotatable(annotatable)
        return 0 if annotatable.nil?
        points = 0
        
        if annotatable.respond_to?(:description) && annotatable.description
          points = points + 1
        end
        unless annotatable_attributes_for(annotatable).nil?
          annotatable_attributes_for(annotatable).each do |attr|
            if non_provider_annotations?(annotatable, attr)
              points = points + 1
            end
          end
        end
        return points
      end
      
      def self.max_points_for_service(service)
        points = 0
        service_annotatables(service).each do |ann|
          points = points + max_points_for_annotatable(ann)
        end
        return points
      end
      
      def self.points_for_service(service)
        points = 0
        service_annotatables(service).each do |ann|
          points = points + points_for_annotatable(ann)
        end
        return points
      end
      
      def self.annotation_level_for_service(service)
        ((points_for_service(service).to_f/max_points_for_service(service).to_f) *100 ).to_i
      end
      
      def self.non_provider_description_annotations?(parent, attr='description')
        if parent.respond_to?(:annotations)
          return true if parent.annotations.collect{|a| a if a.attribute.name.downcase == attr}.compact.count > 0 
        end
        return false
      end
      
    end
  end
end
