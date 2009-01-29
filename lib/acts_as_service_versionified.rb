# BioCatalogue: app/lib/acts_as_service_versionified.rb
#
# Copyright (c) 2008, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

module BioCatalogue
  module Acts #:nodoc:
    module ServiceVersionified #:nodoc:
      def self.included(mod)
        mod.extend(ClassMethods)
      end
      
      module ClassMethods
        def acts_as_service_versionified
          has_one :service_version, 
                  :as => :service_versionified
          
          # This assumes the presence of a 'service' association
          # in the ServiceVersion model.
          has_one :service,
                  :through => :service_version
          
          # This assumes the presence of a 'service_deployments' association
          # in the ServiceVersion model.
          has_many :service_deployments,
                   :through => :service_version
                  
          after_save :save_service_version_record

          class_eval do
            extend BioCatalogue::Acts::ServiceVersionified::SingletonMethods
          end
          include BioCatalogue::Acts::ServiceVersionified::InstanceMethods
        end
      end
      
      module SingletonMethods
        
      end
      
      module InstanceMethods
        
        # This is to update things like the updated_at time
        def save_service_version_record
          if service_version
            service_version.updated_at = Time.now
            service_version.save    # This should only do a partial update (ie: save the updated_at field only).
          end
          
          if service
            service.updated_at = Time.now
            service.save            # This should only do a partial update (ie: save the updated_at field only).
          end
        end
        
        # Method stub that models should reimplement
        def total_annotations_count(source_type)
          0
        end
        
      end
    end
  end
end

ActiveRecord::Base.send(:include, BioCatalogue::Acts::ServiceVersionified)
