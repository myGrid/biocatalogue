# BioCatalogue: lib/tasks/update_maturity_annotations.rake
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

namespace :biocatalogue do
  desc 'Update any BioVeL Maturity and Actions annotations if they have been changed in the BioVeL wiki.'
  task :update_maturity_annotations => :environment do
    puts "\nUpdating maturity annotations for #{SITE_NAME} in #{Rails.env} mode.\n"
    BioCatalogue::Jobs::UpdateMaturityAnnotations.new.perform
  end
end