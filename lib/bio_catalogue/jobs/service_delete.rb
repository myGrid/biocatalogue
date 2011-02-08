# BioCatalogue: lib/bio_catalogue/jobs/service_delete.rb
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# Use this job to perform delete of a service
# in a background process.
#
module BioCatalogue
  module Jobs
    class ServiceDelete < Struct.new(:service)
      def perform
          begin
            service.destroy if service
         	rescue Exception => ex
          	Rails.logger.error("problems deleting a service ") 
            Rails.logger.error(ex.to_s)
         	end
      end   
    end
  end
end