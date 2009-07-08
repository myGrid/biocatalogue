# BioCatalogue: lib/bio_catalogue/jobs/update_urls_to_monitor
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

module BioCatalogue
  module Jobs
    class CheckUrlStatus
      def perform
          # check the status of a url using curl
          BioCatalogue::Monitoring::CheckUrlStatus.run :all => true
        end
      end    
  end
end