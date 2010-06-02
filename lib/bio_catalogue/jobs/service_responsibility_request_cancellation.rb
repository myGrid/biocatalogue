# BioCatalogue: lib/bio_catalogue/jobs/service_responsibility_request_cancellation.rb
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

module BioCatalogue
  module Jobs
    class ServiceResponsibilityRequestCancellation < Struct.new(:owners, :base_host, :service, :current_user, :req )
      def perform
        owners.each{ |owner| UserMailer.deliver_responsibility_request_cancellation(owner, base_host, service, current_user, req) }
      end    
    end
  end
end