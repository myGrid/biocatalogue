# BioCatalogue: lib/bio_catalogue/jobs/update_maturity_annotations.rb
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

module BioCatalogue
  module Jobs
    class UpdateMaturityAnnotations
      def perform
        BioCatalogue::MaturityAnnotation.update_maturity_annotations
      end
    end
  end
end