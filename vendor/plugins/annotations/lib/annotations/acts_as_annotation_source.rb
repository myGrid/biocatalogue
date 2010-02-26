# ActsAsAnnotationSource
module Annotations
  module Acts #:nodoc:
    module AnnotationSource #:nodoc:

      def self.included(base)
        base.send :extend, ClassMethods  
      end

      module ClassMethods
        def acts_as_annotation_source
          has_many :annotations_by,
                   :class_name => "Annotation",
                   :as => :source, 
                   :order => 'created_at ASC'
                   
          send :extend, SingletonMethods
          send :include, InstanceMethods
        end
      end
      
      # Class methods added to the model that has been made acts_as_annotation_source (the mixin source type).
      module SingletonMethods
        # Helper finder to get all annotations for an object of the mixin source type with the ID provided.
        # This is the same as object.annotations with the added benefit that the object doesnt have to be loaded.
        # E.g: User.find_annotations_by(10) will give all annotations by User with ID 34.
        def annotations_by(id)
          obj_type = ActiveRecord::Base.send(:class_name_of_active_record_descendant, self).to_s
          
          Annotation.find(:all,
                          :conditions => { :source_type =>  obj_type, 
                                           :source_id => id },
                          :order => "created_at DESC")
        end
        
        # Helper finder to get all annotations for all objects of the mixin source type, for the annotatable object provided.
        # E.g: User.find_annotations_for('Book', 28) will give all annotations made by all Users for Book with ID 28. 
        def annotations_for(annotatable_type, annotatable_id)
          obj_type = ActiveRecord::Base.send(:class_name_of_active_record_descendant, self).to_s
          
          Annotation.find(:all,
                          :conditions => { :source_type => obj_type,
                                           :annotatable_type =>  annotatable_type, 
                                           :annotatable_id => annotatable_id },
                          :order => "created_at DESC")
        end
      end
      
      # This module contains instance methods
      module InstanceMethods
        # Helper method to get latest annotations
        def latest_annotations(limit=nil)
          Annotation.find(:all,
                          :conditions => { :source_type =>  self.class.name, 
                                           :source_id => id },
                          :order => "created_at DESC",
                          :limit => limit)
        end
        
        def annotation_source_name
          %w{ preferred_name display_name title name }.each do |w|
            return eval("self.#{w}") if self.respond_to?(w)
          end
          return "#{self.class.name}_#{self.id}"
        end
      end
      
    end
  end
end
