# BioCatalogue: lib/tasks/clean_db_for_dev.rake
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

namespace :biocatalogue do
  desc "Clean the database of all confidential etc information so that the data can be used for development and other such purposes."
  task :clean_db_for_dev => :environment do
    
    ActiveRecord::Base.record_timestamps = false
    
    User.all.each do |u|
      u.email = "#{rand(1000000000)}@example.com"
      u.save
    end
    
    ActiveRecord::Base.record_timestamps = true
    
  end
end
