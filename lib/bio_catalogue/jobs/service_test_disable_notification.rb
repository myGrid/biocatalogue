# BioCatalogue: lib/bio_catalogue/jobs/service_test_disable_notification.rb
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

module BioCatalogue
  module Jobs
    class ServiceTestDisableNotification < Struct.new(:user,  :service_test, :to_emails, :base_host)
      def perform
        UserMailer.deliver_service_test_disable_notification(user, service_test, to_emails, base_host)
      end    
    end
  end
end