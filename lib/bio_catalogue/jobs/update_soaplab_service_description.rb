# BioCatalogue: lib/bio_catalogue/jobs/update_soaplab_service_description.rb
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

module BioCatalogue
  module Jobs
    class UpdateSoaplabServiceDescription < Struct.new(:service_id)
      def perform
        service = Service.find(service_id)
        if service 
          begin
            service.latest_version.service_versionified.update_description_from_soaplab!
          rescue Exception => ex
            Rails.logger.error("There was a problem updating descriptions from soaplab")
            Rails.logger.error(ex.to_s)
          end
        end
      end
    end    
  end
end
