# BioCatalogue: lib/tasks/update_service_annotation_levels.rake
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

namespace :biocatalogue do
  namespace :curation do
    desc "Update all service annotation levels"
    task :update_service_annotation_level => :environment do
      Service.find(:all).each  do |service|
        puts "Updataing service annotation level : #{service.id}"      
        service.annotation_level = BioCatalogue::Curation::AnnotationLevel.annotation_level_for_service(service)
        begin
          service.save!
        rescue Exception => ex
          puts "Could set annotation level for service : #{service.id}"
          puts ex.to_s
          Rails.logger.error("Could set annotation level for service : #{service.id}")
          Rails.logger.error(ex.to_s)
        end 
      end
    end
    
    desc "Reset all service annotation levels"
    task :reset_service_annotation_level => :environment do
      Service.find(:all).each  do |service|
        puts "Resetting service annotation level : #{service.id}"      
        begin
          service.annotation_level = nil
          service.save!
        rescue Exception => ex
          Rails.logger.error("Could not rest annotation level for service : #{service.id}")
          Rails.logger.error(ex.to_s)
        end
      end
    end
  end
end