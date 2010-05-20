# BioCatalogue: lib/bio_catalogue/jobs/run_service_updater_for_all.rb
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

module BioCatalogue
  module Jobs
    class RunServiceUpdaterForAll
      def perform
        Service.all.each do |service|
          service.run_service_updater!
        end
      end
    end    
  end
end