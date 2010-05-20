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
        service.run_service_updater! unless service.nil?
      end
    end    
  end
end
