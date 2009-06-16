# ActsAsFavouritable
module Favourites
  module Acts #:nodoc:
    module Favouritable #:nodoc:

      def self.included(base)
        base.send :extend, ClassMethods 
      end

      module ClassMethods
        def acts_as_favouritable
          has_many :favourites, 
                   :as => :favouritable, 
                   :dependent => :destroy
          
          send :extend, SingletonMethods
          send :include, InstanceMethods
        end
      end
      
      # Class methods added to the model that has been made acts_as_favouritable (ie: the mixin favouritable type).
      module SingletonMethods
        # Helper finder to get all favourites for an object of the mixin favouritable type with the ID provided.
        # This is the same as object.favourites with the added benefit that the object doesnt have to be loaded.
        # E.g: Book.find_favourites_for(34) will give all favourites for the Book with ID 34.
        def find_favourites_for(id)
          obj_type = ActiveRecord::Base.send(:class_name_of_active_record_descendant, self).to_s
          
          Favourite.find(:all,
                          :conditions => { :favouritable_type =>  obj_type, 
                                           :favouritable_id => id },
                          :order => "created_at DESC")
        end
        
        # Helper finder to get all favourites for all objects of the mixin favouritable type, by the user specified.
        # E.g: Book.find_favourites_by(10) will give all favourites that are for Books, by User with ID 10.
        def find_favourites_by(user_id)
          obj_type = ActiveRecord::Base.send(:class_name_of_active_record_descendant, self).to_s
          
          Favourite.find(:all,
                         :conditions => { :favouritable_type =>  obj_type, 
                                          :user_id => user_id },
                         :order => "created_at DESC")
        end
      end
      
      # This module contains instance methods
      module InstanceMethods
        
        # Provides a default implementation to get the display name for 
        # an favouritable object, that can be overrided.
        def favouritable_name
          %w{ display_name title name }.each do |w|
            return eval("self.#{w}") if self.respond_to?(w)
          end
          return "#{self.class.name}_#{id}"
        end
        
        # Helper method to get latest favourites
        def latest_favourites(limit=nil)
          obj_type = ActiveRecord::Base.send(:class_name_of_active_record_descendant, self.class).to_s
          
          Favourite.find(:all,
                         :conditions => { :favouritable_type =>  obj_type, 
                                          :favouritable_id => self.id },
                         :order => "created_at DESC",
                         :limit => limit)
        end
        
        # Check to see if a user already favourited this favouritable
        def favourited_by_user?(user_id_to_check)
          favourited = false
          
          obj_type = ActiveRecord::Base.send(:class_name_of_active_record_descendant, self.class).to_s
          
          favs = Favourite.find(:all,
                                :conditions => { :favouritable_type =>  obj_type, 
                                                 :favouritable_id => self.id,
                                                 :user_id => user_id_to_check })
          
          favourited = true unless favs.empty?
          
          return favourited
        end
      end
      
    end
  end
end
