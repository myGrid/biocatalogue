# BioCatalogue: lib/bio_catalogue/jobs/calculate_service_test_success_rate.rb
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

module BioCatalogue
  module Jobs
    class CalculateServiceTestSuccessRate < Struct.new(:test_result)
      def perform
        test_result.success_rate
      end    
    end
  end
end