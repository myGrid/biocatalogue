# BioCatalogue: lib/tasks/update_test_success_rates.rake
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

namespace :biocatalogue do
  namespace :monitoring do
    desc "update the success rates for service tests"
    task :update_test_success_rate => :environment do
      ServiceTest.all.each  do |st|
        puts "Updating success rate for test : #{st.id}"
        st.update_success_rate!
      end
    end
  end
end