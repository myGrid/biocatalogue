# BioCatalogue: lib/bio_catalogue/jobs/submit_soaplab_services
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

module BioCatalogue
  module Jobs
    class SubmitSoaplabServices
      attr_accessor :server
      attr_accessor :user
      def initialize(server, user)
        @server = server
        @user   = user
      end
      def perform
          # submit services in a soaplab server
          new_wsdl_urls, existing_services, error_urls = @server.save_services(@user)
          if error_urls.empty?
            Rails.logger.info("All services submitteed successfully")
            Rails.logger.info("#{new_wsdl_urls.count} new and #{existing_services.count} already registered services in this server")
          else
            Rails.logger.error("ERROR: there were problems submitting #{error_urls.count} services" )
          end
        end
      end    
  end
end