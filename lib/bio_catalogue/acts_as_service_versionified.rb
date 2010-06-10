# BioCatalogue: lib/bio_catalogue/acts_as_service_versionified.rb
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

module BioCatalogue
  module ActsAsServiceVersionified #:nodoc:
    def self.included(mod)
      mod.extend(ClassMethods)
    end
    
    module ClassMethods
      def acts_as_service_versionified
        
        acts_as_annotatable
        
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
          extend BioCatalogue::ActsAsServiceVersionified::SingletonMethods
        end
        include BioCatalogue::ActsAsServiceVersionified::InstanceMethods
        
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
          service_version.update_attribute(:updated_at, Time.now)
        end
        
        if service
          service.update_attribute(:updated_at, Time.now)
        end
      end
      
      # ==========================================================
      # Instance level method stubs that models should reimplement
      # ----------------------------------------------------------
      
      def service_type_name
        ""  
      end
      
      def total_db_metadata_fields_count
        0
      end
      
      # NOTE: this method should ONLY take into account annotations stored through the annotations plugin.
      def total_annotations_count(source_type)
        0
      end
      
      # ==========================================================
      
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
        annotations_data = BioCatalogue::Annotations.preprocess_annotations_data(annotations_data)
        
        # Split into seperate annotation data sets

        service_version_annotations = { }              # Annotations just for the service_version object
        service_version_instance_annotations = { }     # Annotations just for the soap_service object
        service_container_annotations = { }            # Annotations just for the parent service container object
        
        # Process
        
        annotations_data.each do |attrib, value|
          case attrib.to_s.downcase
            when "tag", "category", "name", "alternative_name", "display_name"
              service_container_annotations[attrib] = value
            when "version"
              service_version_annotations[attrib] = value
            else
              # By default, annotations are allocated to the service version instance
              service_version_instance_annotations[attrib] = value
          end
        end
        
        # Create annotations
        self.service_version(true).create_annotations(service_version_annotations, actual_submitter) unless service_version_annotations.blank?
        self.create_annotations(service_version_instance_annotations, actual_submitter) unless service_version_instance_annotations.blank?
        self.service(true).create_annotations(service_container_annotations, actual_submitter) unless service_container_annotations.blank?
      end
      
      def preferred_description
        # Either the description from the service description doc, 
        # or the last description annotation.
        
        # TODO: need a better way! Taking into account curators, curator approval, etc
        
        desc = self.description
        
        if desc.blank?
          desc = self.annotations_with_attribute("description").first.try(:value)
        end
        
        return desc
      end
      
      def preferred_documentation_url
        # Either the doc url from the db table, 
        # or the last doc url annotation.
        
        # TODO: need a better way! Taking into account curators, curator approval, etc
        
        doc_url = self.documentation_url
        
        if doc_url.blank?
          doc_url = self.annotations_with_attribute("documentation_url").first.try(:value)
        end
        
        return doc_url
      end
      
      def has_description?
        return (!self.description.blank? or !self.annotations_with_attribute('description').blank?)
      end

      def has_documentation_url?
        return (!self.documentation_url.blank? or !self.annotations_with_attribute('documentation_url').blank?)
      end


      protected

      
      # This method should be used as part of the submission process, 
      # ideally wrapped in a transaction, 
      # after the service version instance is created,
      # in order to create the parent Service, ServiceVersion and ServiceDeployment objects and assign the necessary data.
      def perform_post_submit(endpoint, actual_submitter)
        # Try and find location of the service from the url of the endpoint.
        wsdl_geoloc = BioCatalogue::Util.url_location_lookup(endpoint)
        city, country = BioCatalogue::Util.city_and_country_from_geoloc(wsdl_geoloc)
        
        hostname = Addressable::URI.parse(endpoint).host
        provider_name = hostname.gsub(".", "-")
        
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
        
        provider_hostname = ServiceProviderHostname.find_or_initialize_by_hostname(hostname)
        
        if provider_hostname.service_provider.nil?
          provider = ServiceProvider.find_or_create_by_name(provider_name)
          provider_hostname.service_provider_id = provider.id
          provider_hostname.save!
        else
          provider = provider_hostname.service_provider
        end
        
        new_service_deployment.provider = provider 
        new_service_deployment.service = new_service
        new_service_deployment.submitter = actual_submitter
                                                      
        return new_service.save!
      end
      
    end
  end
end

ActiveRecord::Base.send(:include, BioCatalogue::ActsAsServiceVersionified)
