# ActsAsCommentable
module BioCatalogue
  module Acts #:nodoc:
    module Annotatable #:nodoc:

      def self.included(base)
        base.extend ClassMethods  
      end

      module ClassMethods
        def acts_as_annotatable
          has_many :annotations, :as => :annotatable, :dependent => :destroy, :order => 'created_at ASC'
          include BioCatalogue::Acts::Annotatable::InstanceMethods
          extend BioCatalogue::Acts::Annotatable::SingletonMethods
        end
      end
      
      # This module contains class methods
      module SingletonMethods
        # Helper method to lookup for annotations for a given object.
        # This method is equivalent to obj.annotations.
        def find_annotations_for(obj)
          annotatable = ActiveRecord::Base.send(:class_name_of_active_record_descendant, self).to_s
         
          Annotation.find(:all,
            :conditions => ["annotatable_id = ? and annotatable_type = ?", obj.id, annotatable],
            :order => "created_at DESC"
          )
        end
        
        # Helper class method to lookup annotations for
        # the mixin annotatable type written by a given user.  
        # This method is NOT equivalent to Annotation.find_annotations_for_user
        def find_annotations_by_user(user) 
          annotatable = ActiveRecord::Base.send(:class_name_of_active_record_descendant, self).to_s
          
          Annotation.find(:all,
            :conditions => ["user_id = ? and annotatable_type = ?", user.id, annotatable],
            :order => "created_at DESC"
          )
        end
      end
      
      # This module contains instance methods
      module InstanceMethods
        # Helper method to sort annotations by date
        def annotation_ordered_by_submitted
          Annotation.find(:all,
            :conditions => ["annotatable_id = ? and annotatable_type = ?", id, self.type.name],
            :order => "created_at DESC"
          )
        end
        
        # Helper method that defaults the submitted time.
        def add_annotation(annotation)
          annotations << annotation
        end
      end
      
    end
  end
end
