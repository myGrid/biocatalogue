require Rails.root.join('app', 'helpers', 'services_helper')
include ServicesHelper

namespace :biocatalogue do
  desc 'Map the Categories of all services to the EDAM Topic equivalent according to the mapping in services_helper.rb'
  task :convert_categories_to_edam => :environment do

    Service.all.each do |service|
      service_categories = service.annotations_with_attribute('category')
      service_categories.each do |category|
        original_name = category.value_content
        new_name = map_categories_to_edam_topics(original_name)[:name]
        puts "Mapping #{original_name} to #{new_name}"
        source = category.source
        if service.create_annotations({ "edam_topic" => new_name }, source)
          puts "- successfully created new edam topic"
          puts "- deleted old category" #if category.delete
        end
      end
    end
  end
end
