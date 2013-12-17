# ActsAsFavouriter
#
# This module MUST only be used by the User model.
# I.e.: the User model is the only thing that can act as a favouriter.
module Favourites
  module Acts #:nodoc:
    module Favouriter #:nodoc:

      def self.included(base)
        base.send :extend, ClassMethods 
      end

      module ClassMethods
        def acts_as_favouriter
          has_many :favourites, 
                   :order => 'created_at ASC',
                   :dependent => :destroy
          
          send :extend, SingletonMethods
          send :include, InstanceMethods
        end
      end
      
      # Class methods added to the User model (which is the only thing that can act as a favouriter).
      module SingletonMethods
        # Helper finder to get all favourites that belong to the specified user.
        # E.g: User.find_favourites_for(6) will give all favourites made by User with ID 6.
        #
        # Note: this is essentially the same as doing user.favourites, but with the added advantage that this
        # finder doesn't require you to load up a user object in the first place.
        def find_favourites_by(user_id)
          Favourite.by_user(user_id)
        end
      end
      
      # This module contains instance methods
      module InstanceMethods
        # Helper method to get latest favourites for a user.
        def latest_favourites(limit=nil)
          Favourite.find(:all,
                         :conditions => { :user_id => self.id },
                         :order => "created_at DESC",
                         :limit => limit)
        end
        
        # Convenience method to get all the items that a user has favourited, in one collection.        
        def favourited_items
          self.favourites.each do |f|
            f.favouritable
          end
        end
      end
    end
  end
end