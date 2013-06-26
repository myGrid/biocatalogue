# BioCatalogue: lib/bio_catalogue/jobs/service_owner_request_notification.rb
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

module BioCatalogue
  module Jobs
    class ServiceOwnerRequestNotification < Struct.new(:owners, :base_host, :service, :current_user)
      def perform
        owners.each  do |owner|
          begin
            UserMailer.responsibility_request_notification(owner, base_host, service, current_user).deliver
          rescue Exception => ex
            Rails.logger.error("Failed to deliver mail")
            Rails.logger.error(ex.to_s)
          end
        end
      end    
    end
  end
end