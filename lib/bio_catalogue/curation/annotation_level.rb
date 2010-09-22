# BioCatalogue: lib/bio_catalogue/curation/annotation_lever.rb
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# A helper module for calculating the level of annotation of a service.

# This module does a simple calculation for the level of annotation of a service.
# It assigns weighted points for the presence of annotations for service attributes.
# If a value for an attribute is present, it is weighted based on the attribute type and 
# source of the attribute value. Provider attribute values, like descriptions from
# interface documents have a higher weighting than those from users(community). Also
# a service level description will have a higher weighting than an input or output description.

# The max number of points each service can have depends on the number of operations and
# the number of inputs and outputs that these operations have.

# The annotation level is determine as a ratio of the point obtained over the possible max

#TODO : Annotation level for rest services.

module BioCatalogue

  module Curation
    module AnnotationLevel
  
      @attribute_weighting = {'service_description'      => 20,
                              'description_from_soaplab' => 20,
                                'operation_description'  => 10,
                                'input_description'      => 5,
                                'output_description'     => 5 }
                            
      def self.annotation_level_for_soap_service(service)
        return if !service.is_a?(SoapService)
        points = []
        
        points << @attribute_weighting['service_description'] if (service.description || non_provider_description_annotations?(service))
        points << @attribute_weighting['description_from_soaplab'] if service.description_from_soaplab
        
        service.soap_operations.each do |op|
          if op.description || non_provider_description_annotations?(op)
            points << @attribute_weighting['operation_description'] 
        
            op.soap_inputs.each do |input|
              points << @attribute_weighting['input_description'] if (input.description || non_provider_description_annotations?(input))
            end
            op.soap_outputs.each do |output|
              points << @attribute_weighting['output_description'] if (output.description || non_provider_description_annotations?(output))
            end
          end
        end  
        return Float(points.sum)
      end
      
      def self.annotation_level_for_rest_service(service)
        return if !service.is_a?(RestService)
        
        points = []
        points << @attribute_weighting['service_description'] if (service.description || non_provider_description_annotations?(service))
        service.rest_resources.each do |res|
          if res.description || non_provider_description_annotations?(res)
            points << @attribute_weighting['operation_description'] 
          end
        end
        
        return Float(points.sum)
      end
      
      def self.total_annotation_points_for_rest_service(service)
        points = []
        points << @attribute_weighting['service_description']
        points << @attribute_weighting['operation_description'] if service.rest_resources.empty?  # should have at least one resource
        service.rest_resources.each do |res|
          points << @attribute_weighting['operation_description'] 
        end  
        return Float(points.sum)
      end
      
      def self.total_annotation_points_for_soap_service(service)
        points = []
        points << @attribute_weighting['service_description']
        points << @attribute_weighting['description_from_soaplab'] if service.soaplab_service?
        service.soap_operations.each do |op|
          points << @attribute_weighting['operation_description']
          op.soap_inputs.each do |input|
            points << @attribute_weighting['input_description'] 
          end
          op.soap_outputs.each do |output|
            points << @attribute_weighting['output_description'] 
          end
        end
        return Float(points.sum)
      end
      
      def self.percentage_description_annotation_level_for_soap_service(service)
        rate = annotation_level_for_soap_service(service)/total_annotation_points_for_soap_service(service)
        return (rate*100).to_i
      end
      
      def self.percentage_description_annotation_level_for_rest_service(service)
        rate = annotation_level_for_rest_service(service)/total_annotation_points_for_rest_service(service)
        return (rate*100).to_i
      end
      
      def self.percentage_description_annotation_levels_for_soap_services(services)
        ann_levels = {}
        services.each{|s| ann_levels["#{s.id}"] = percentage_description_annotation_level_for_soap_service(s) }
        return ann_levels.sort {|a,b| a[1] <=> b[1]}
      end
      
      
      protected
      
      def self.non_provider_description_annotations?(parent, attr='description')
        if parent.respond_to?(:annotations)
          return true if parent.annotations.collect{|a| a if a.attribute.name.downcase == attr}.compact.count > 0 
        end
        return false
      end
      
    end
  end
end