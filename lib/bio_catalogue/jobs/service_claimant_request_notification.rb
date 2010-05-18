# BioCatalogue: lib/bio_catalogue/jobs/service_claimant_request_notification.rb
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

module BioCatalogue
  module Jobs
    class ServiceClaimantRequestNotification < Struct.new(:current_user, :base_host, :service )
      def perform
         UserMailer.deliver_claimant_responsibility_notification(current_user, base_host, service ) 
      end    
    end
  end
end