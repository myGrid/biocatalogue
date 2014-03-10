require "#{Rails.root}/app/helpers/ontology_helper"
include OntologyHelper

namespace :biocatalogue do
  desc 'Load up the EDAM ontology into memory'
  task :load_edam_ontology => :environment do
    puts 'Reading EDAM ontology'
    BioCatalogue::Ontologies::EdamReader.instance.clear_cache
    classes = BioCatalogue::Ontologies::EdamReader.instance.class_hierarchy
    #hash_by_uri['http://edamontology.org/topic_0077'].try(:label)
    options = render_ontology_class_options classes
    puts options
  end
end
