# ActsAsAnnotatable
module Annotations
  module Acts #:nodoc:
    module Annotatable #:nodoc:

      def self.included(base)
        base.send :extend, ClassMethods  
      end

      module ClassMethods
        def acts_as_annotatable
          has_many :annotations, 
                   :as => :annotatable, 
                   :dependent => :destroy, 
                   :order => 'created_at ASC'
                   
          send :extend, SingletonMethods
          send :include, InstanceMethods
        end
      end
      
      # Class methods added to the model that has been made acts_as_annotatable (the mixing annotatable type).
      module SingletonMethods
        # Helper finder to get all annotations for an object of the mixin annotatable type with the ID provided.
        # This is the same as object.annotations with the added benefit that the object doesnt have to be loaded.
        # E.g: Book.find_annotations_for(34) will give all annotations Book with ID 34.
        def annotations_for(id)
          obj_type = ActiveRecord::Base.send(:class_name_of_active_record_descendant, self).to_s
          
          Annotation.find(:all,
                          :conditions => { :annotatable_type =>  obj_type, 
                                           :annotatable_id => id },
                          :order => "created_at DESC")
        end
        
        # Helper finder to get all annotations for all objects of the mixin annotatable type, by the source provided.
        # E.g: Book.find_annotations_by('User', 10) will give all annotations for all Books by User with ID 10. 
        def annotations_by(source_type, source_id)
          obj_type = ActiveRecord::Base.send(:class_name_of_active_record_descendant, self).to_s
          
          Annotation.find(:all,
                          :conditions => { :annotatable_type =>  obj_type, 
                                           :source_type => source_type,
                                           :source_id => source_id },
                          :order => "created_at DESC")
        end
      end
      
      # This module contains instance methods
      module InstanceMethods
        # Helper method to get latest annotations
        def latest_annotations(limit=nil)
          Annotation.find(:all,
                          :conditions => { :annotatable_type =>  self.class.name, 
                                           :annotatable_id => id },
                          :order => "created_at DESC",
                          :limit => limit)
        end
        
        # Finder to get annotations with a specific attribute
        def annotations_with_attribute(attrib)
          return [] if attrib.blank?
          
          Annotation.find(:all,
                          :joins => "JOIN annotation_attributes ON annotations.attribute_id = annotation_attributes.id",
                          :conditions => [ "annotations.annotatable_type = ? AND annotations.annotatable_id = ? AND annotation_attributes.name = ?", 
                                           self.class.name, 
                                           id,
                                           attrib.strip.downcase ],
                          :order => "created_at DESC")
        end
        
        def annotatable_name
          %w{ name title }.each do |w|
            return eval("self.#{w}") if self.respond_to?(w)
          end
          return "#{self.class.name}_#{id}"
        end
      end
      
    end
  end
end
