# BioCatalogue: lib/tasks/seed_service_responsibles.rake
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

namespace :biocatalogue do
  namespace :monitoring do
    desc "Seed service responsibles with submiters"
    task :seed_service_responsibles => :environment do
      Service.all.each  do |service|
        puts "Seeding responsible for service : #{service.id}"
        ServiceResponsible.add(service.submitter.id, service.id) if service.submitter.class.name == "User"
      end
    end
  end
end