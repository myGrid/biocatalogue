# BioCatalogue: lib/tasks/update_test_success_rates.rake
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

namespace :biocatalogue do
  namespace :monitoring do
    desc "update cached service test status"
    task :update_cached_service_test_status => :environment do
      ServiceTest.all.each  do |st|
        puts "Updating cached status for test : #{st.id}"
        Rails.logger.info("Updating cached status for test : #{st.id}")
        st.update_cached_status!
      end
    end
  end
end