# BioCatalogue: app/helpers/search_helper.rb
#
# Copyright (c) 2008, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.

module SearchHelper
  
  def search_provide_query_text
    'Please specify a search query...<br/>Examples: "blast" "blast AND ebi" "blast OR ebi"'
  end
  
  def search_item_ids_to_objects(item_ids, result_type)
    result_type.classify.constantize.find(item_ids)
  end
  
end
