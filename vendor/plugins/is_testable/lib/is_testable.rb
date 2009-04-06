# IsTestable
module BioCatalogue
  module Is #:nodoc:
    module Testable #:nodoc:

      def self.included(base)
        base.extend ClassMethods  
      end

      module ClassMethods
        def is_testable
          has_many :service_tests, :as => :testable, :dependent => :destroy, :order => 'created_at ASC'
          include BioCatalogue::Is::Testable::InstanceMethods
          extend BioCatalogue::Is::Testable::SingletonMethods
        end
      end
      
      # This module contains class methods
      module SingletonMethods
        # Helper method to lookup for tests for a given web service.
        # This method is equivalent to service.service_tests.
        def find_tests_for(obj)
          testable = ActiveRecord::Base.send(:class_name_of_active_record_descendant, self).to_s
         
          ServiceTest.find(:all,
            :conditions => ["testable_id = ? and testable_type = ?", obj.id, testable],
            :order => "created_at DESC"
          )
        end
        
        # Helper class method to lookup test for
        # the mixin testable type written by a given user.  
        # This method is NOT equivalent to ServiceTest.find_tests_for_user
        def find_tests_by_user(user) 
          testable = ActiveRecord::Base.send(:class_name_of_active_record_descendant, self).to_s
          
          ServiceTest.find(:all,
            :conditions => ["user_id = ? and testable_type = ?", user.id, testable],
            :order => "created_at DESC"
          )
        end
      end
      
      # This module contains instance methods
      module InstanceMethods
        # Helper method to sort comments by date
        def tests_ordered_by_submitted
          ServiceTest.find(:all,
            :conditions => ["testable_id = ? and testable_type = ?", id, self.type.name],
            :order => "created_at DESC"
          )
        end
        
        # Helper method that defaults the submitted time.
        def add_service_test(test)
          service_tests << test
        end
      end
      
    end
  end
end
