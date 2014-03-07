require 'rdf'

module BioCatalogue
  module Ontologies

    class Swo_licenseReader < OntologyReader

      def default_parent_class_uri
        RDF::URI.new('http://www.ebi.ac.uk/swo/SWO_0000002')
        #RDF::URI.new("http://www.mygrid.org.uk/ontology/JERMOntology#Experimental_assay_type")
      end

      def ontology_file
        'swo_license.owl'
      end

    end
  end
end
