# BioCatalogue: app/lib/acts_as_service_versionified.rb
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics 
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
        
        # =======================================================
        # Class level method stubs that models should reimplement
        # -------------------------------------------------------
        
        def check_duplicate(endpoint)
          nil
        end
        
        # =======================================================
        
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
        
        # ==========================================================
        # Instance level method stubs that models should reimplement
        # ----------------------------------------------------------
        
        def service_type_name
          ""  
        end
        
        def total_annotations_count(source_type)
          0
        end
        
        # ==========================================================
        
        protected
        
        # This method should be used as part of the submission process, 
        # ideally wrapped in a transaction, 
        # after the service version instance is created,
        # in order to create the parent Service, ServiceVersion and ServiceDeployment objects and assign the necessary data.
        def perform_post_submit(endpoint, actual_submitter)
          # Try and find location of the service from the url of the endpoint.
          wsdl_geoloc = BioCatalogue::Util.url_location_lookup(endpoint)
          city, country = BioCatalogue::Util.city_and_country_from_geoloc(wsdl_geoloc)
          
          # Create the associated service, service_version and service_deployment objects.
          # We can assume here that this is the submission of a completely new service in BioCatalogue.
          
          new_service = Service.new(:name => self.name)
          
          new_service.submitter = actual_submitter
                                    
          new_service_version = new_service.service_versions.build(:version => "1", 
                                                                   :version_display_text => "1")
          
          new_service_version.service_versionified = self
          new_service_version.submitter = actual_submitter
          
          new_service_deployment = new_service_version.service_deployments.build(:endpoint => endpoint,
                                                                                 :city => city,
                                                                                 :country => country)
          
          new_service_deployment.provider = ServiceProvider.find_or_create_by_name(Addressable::URI.parse(endpoint).host)
          new_service_deployment.service = new_service
          new_service_deployment.submitter = actual_submitter
                                                        
          return new_service.save!
        end
        
        # Given a hash of annotation data, this method will process them 
        # and allocate the appropriate Annotation objects to the appropriate objects of this service.
        #
        # For example, tags go on the parent Service object, but things like descriptions, ratings 
        # and so on go on the service version instance object (eg: SoapService).
        #
        # This should be used instead of object.create_annotations when preprocessing is required and 
        # different annotations need to be allocated to different objects of a service.
        def process_annotations_data(annotations_data, actual_submitter)
          # Preprocess (so that we get the correct structure to work with)
          annotations_data = BioCatalogue::Util.preprocess_annotations_data(annotations_data)
          
          # Split into seperate annotation data sets
          
          service_version_instance_annotations = { }     # Annotations just for the soap_service object
          service_container_annotations = { }            # Annotations just for the parent service container object
          
          # Process
          
          annotations_data.each do |attrib, value|
            case attrib.to_s
              when "tag"
                service_container_annotations[attrib] = value
              else
                # By default, annotations are allocated to the service version instance
                service_version_instance_annotations[attrib] = value
            end
          end
          
          # Create annotations
          
          self.create_annotations(service_version_instance_annotations, actual_submitter) unless service_version_instance_annotations.blank?
          self.service(true).create_annotations(service_container_annotations, actual_submitter) unless service_container_annotations.blank?
        end
      end
    end
  end
end

ActiveRecord::Base.send(:include, BioCatalogue::Acts::ServiceVersionified)
