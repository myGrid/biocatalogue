# BioCatalogue: lib/bio_catalogue/jobs/run_service_update_checker.rb
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

module BioCatalogue
  module Jobs
    class RunServiceUpdater < Struct.new(:service_id)
      def perform
        service = Service.find_by_id(service_id)
        
        # Run SoapService#update_from_latest_wsdl! for all SoapService variants of this Service
        service.service_version_instances_by_type("SoapService").each do |soap_service|
          soap_service.update_from_latest_wsdl!
        end
      end
    end    
  end
end
