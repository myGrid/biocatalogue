require 'rdf'

module BioCatalogue
  module Ontologies

    class EdamReader < OntologyReader

      def default_parent_class_uri
        RDF::URI.new('http://edamontology.org/topic_0003')
        #RDF::URI.new("http://www.mygrid.org.uk/ontology/JERMOntology#Experimental_assay_type")
      end

      def ontology_file
        'low_fat_edam.owl'
        #'JERM-RDFXML.owl'
      end

    end
  end
end
