# BioCatalogue: lib/tasks/update_service_annotation_levels.rake
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

namespace :biocatalogue do
  namespace :curation do
    desc "Update service annotation levels"
    task :update_service_annotation_level => :environment do
      Service.find(:all).each  do |service|
        puts "Updataing service annotation level : #{service.id}"      
        service.annotation_level = BioCatalogue::Curation::AnnotationLevel.annotation_level_for_service(service)
        begin
        	service.save!
        rescue Exception => ex
        	logger.error("Could not update annotation level for service : #{service.id}")
        	logger.error("ex.to_s")
        end
      end
    end
  end
end