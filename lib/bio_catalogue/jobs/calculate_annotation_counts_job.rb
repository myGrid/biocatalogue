# BioCatalogue: lib/bio_catalogue/jobs/calculate_annotation_counts_job.rb
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

module BioCatalogue
  module Jobs
    class CalculateAnnotationCountsJob
      def perform
        Service.all.each do |service|
          # Call the method that calculates and returns the metadata counts, making sure that we set reload to true,
          # as that method currently takes care of caching that data, as we require...
          BioCatalogue::Annotations.metadata_counts_for_service(service, true)
        end
      end    
    end
  end
end