# BioCatalogue: lib/bio_catalogue/jobs/update_stats.rb
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

module BioCatalogue
  module Jobs
    class UpdateStats
      def perform
        BioCatalogue::Stats.generate_current_stats
      end    
    end
  end
end