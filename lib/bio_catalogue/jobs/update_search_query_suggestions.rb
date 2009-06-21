# BioCatalogue: lib/bio_catalogue/jobs/update_search_query_suggestions.rb
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

module BioCatalogue
  module Jobs
    class UpdateSearchQuerySuggestions
      def perform
          BioCatalogue::Search.update_search_query_suggestions_file
        end
      end    
  end
end