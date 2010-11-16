# BioCatalogue: lib/bio_catalogue/jobs/update_service_test_success_rate.rb
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

module BioCatalogue
  module Jobs
    class UpdateServiceTestSuccessRate < Struct.new(:test_result)
      def perform
        begin
          test_result.update_success_rate!
        rescue Exception =>ex
          Rails.logger.error("There was a problem updating success rate for a test ")
          Rails.logger.error(ex.to_s)
        end
      end    
    end
  end
end