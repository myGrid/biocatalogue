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
        # Helper finder to get all objects of the mixin annotatable type that have the specified attribute name and value.
        # NOTE (1): both the attribute name and the value will be treated case insensitively.
        # NOTE (2): the objects returned are Read Only.
        def with_annotations_with_attribute_name_and_value(attribute_name, value)
          return [ ] if attribute_name.blank? or value.nil?
          
          obj_type = ActiveRecord::Base.send(:class_name_of_active_record_descendant, self).to_s
          
          anns = Annotation.find(:all,
                                 :joins => "JOIN annotation_attributes ON annotations.attribute_id = annotation_attributes.id",
                                 :conditions => [ "annotations.annotatable_type = ? AND annotation_attributes.name = ? AND annotations.value = ?", 
                                                  obj_type, 
                                                  attribute_name.strip.downcase,
                                                  value.strip.downcase ])
                                                  
          return anns.map{|a| a.annotatable}.uniq
        end
        
        # Helper finder to get all annotations for an object of the mixin annotatable type with the ID provided.
        # This is the same as object.annotations with the added benefit that the object doesnt have to be loaded.
        # E.g: Book.find_annotations_for(34) will give all annotations Book with ID 34.
        def find_annotations_for(id)
          obj_type = ActiveRecord::Base.send(:class_name_of_active_record_descendant, self).to_s
          
          Annotation.find(:all,
                          :conditions => { :annotatable_type =>  obj_type, 
                                           :annotatable_id => id },
                          :order => "created_at DESC")
        end
        
        # Helper finder to get all annotations for all objects of the mixin annotatable type, by the source provided.
        # E.g: Book.find_annotations_by('User', 10) will give all annotations for all Books by User with ID 10. 
        def find_annotations_by(source_type, source_id)
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
                          :conditions => { :annotatable_type =>  ActiveRecord::Base.send(:class_name_of_active_record_descendant, self.class).to_s, 
                                           :annotatable_id => id },
                          :order => "created_at DESC",
                          :limit => limit)
        end
        
        # Finder to get annotations with a specific attribute.
        # The input parameter is the attribute name 
        # (either a String or a Symbol representing the attribute's name).
        # NOTE: the objects returned are Read Only.
        def annotations_with_attribute(attrib)
          return [] if attrib.blank?
          
          attrib = attrib.strip.downcase if attrib.is_a? String
          
          Annotation.find(:all,
                          :joins => "JOIN annotation_attributes ON annotations.attribute_id = annotation_attributes.id",
                          :conditions => [ "annotations.annotatable_type = ? AND annotations.annotatable_id = ? AND annotation_attributes.name = ?", 
                                           ActiveRecord::Base.send(:class_name_of_active_record_descendant, self.class).to_s, 
                                           id,
                                           attrib ],
                          :order => "created_at DESC")
        end
        
        # Finder to get annotations with a specific attribute by a specific source.
        # The first input parameter is the attribute name 
        # (either a String or a Symbol representing the attribute's name).
        # The second input is the source.
        # NOTE: the objects returned are Read Only.
        def annotations_with_attribute_and_by_source(attrib, source)
          return [] if attrib.blank? or source.nil?
          
          attrib = attrib.strip.downcase if attrib.is_a? String
          
          Annotation.find(:all,
                          :joins => "JOIN annotation_attributes ON annotations.attribute_id = annotation_attributes.id",
                          :conditions => [ "annotations.annotatable_type = ? AND annotations.annotatable_id = ? AND annotations.source_type = ? AND annotations.source_id = ? AND annotation_attributes.name = ?", 
                                           ActiveRecord::Base.send(:class_name_of_active_record_descendant, self.class).to_s, 
                                           id,
                                           source.class.name,
                                           source.id,
                                           attrib ],
                          :order => "created_at DESC")
        end
        
        def annotatable_name
          %w{ name title }.each do |w|
            return eval("self.#{w}") if self.respond_to?(w)
          end
          return "#{self.class.name}_#{id}"
        end
        
        # Returns the number of annotations on this annotatable object by the source type specified.
        # "all" (no case sensitive) can be provided to get all annotations regardless of source type.
        # E.g.: book.count_annotations_by("User") or book.count_annotations_by("All")
        def count_annotations_by(source_type_in)
          if source_type_in == nil || source_type_in.downcase == "all"
            return self.annotations.count
          else
            return self.annotations.count(:conditions => [ "source_type = ?", source_type_in ])  
          end
        end
        
        # Use this method to create many annotations from a Hash of data.
        # Arrays for Hash values will be converted to multiple annotations.
        # Blank values (nil or empty string) will be ignored and thus annotations
        # will not be created for them.
        #
        # Returns an array of Annotation objects of the annotations that were
        # successfully created.
        #
        # Code example:
        # -------------
        # data = { "tag" => [ "tag1", "tag2", "tag3" ], "description" => "This is a book" }
        # book.create_annotations(data, current_use)
        def create_annotations(annotations_data, source)
          anns = [ ]
          
          annotations_data.each do |attrib, val|
            unless val.blank?
              if val.is_a? Array
                val.each do |val_inner|
                  unless val_inner.blank?
                    ann = self.annotations << Annotation.new(:attribute_name => attrib, 
                                                 :value => val_inner, 
                                                 :source_type => source.class.name, 
                                                 :source_id => source.id)
                    
                    unless ann.nil? || ann == false
                      anns << ann
                    end
                  end
                end
              else
                ann = self.annotations << Annotation.new(:attribute_name => attrib, 
                                             :value => val, 
                                             :source_type => source.class.name, 
                                             :source_id => source.id)
                
                unless ann.nil? || ann == false
                  anns << ann
                end
              end
            end
          end
          
          return anns
        end
      end
      
    end
  end
end
