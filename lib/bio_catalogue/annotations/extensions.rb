# BioCatalogue: lib/bio_catalogue/annotations/extensions.rb
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# A helper module for annotations related extensions, that works on top of the Annotations plugin.
# This could be extensions to ActiveRecord models, etc.

module BioCatalogue
  module Annotations
    module Extensions
      
      # Creates a virtual field that will either get the value from an Annotation 
      # (of the annotation attribute name specified), or fallback to use a given field 
      # of the model object.
      module VirtualFieldFromAnnotationWithFallback
        def self.included(mod)
          mod.extend(ClassMethods)
        end
        
        module ClassMethods
          def virtual_field_from_annotation_with_fallback(virtual_field_name, fallback_field, annotation_attribute_name)
            
            return if virtual_field_name.blank? or fallback_field.blank? or annotation_attribute_name.nil?
              
            define_method(virtual_field_name.to_sym) do
              anns = self.annotations_with_attribute(annotation_attribute_name.to_s)
              if anns.empty?
                return eval("self.#{fallback_field}")
              else
                return anns.first.value
              end
            end
              
          end
        end
      end
    
    end
  end
end

ActiveRecord::Base.send(:include, BioCatalogue::Annotations::Extensions::VirtualFieldFromAnnotationWithFallback)