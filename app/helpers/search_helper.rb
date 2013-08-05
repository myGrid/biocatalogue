# BioCatalogue: app/helpers/search_helper.rb
#
# Copyright (c) 2008, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.

module SearchHelper
  
  def search_provide_query_text
    'Please specify a search query...<br/>Examples: "blast" "blast AND ebi" "blast OR ebi"'.html_safe
  end
  
  # For a list of integer IDs
  def search_item_ids_to_objects(item_ids, result_type)
    BioCatalogue::Mapper.item_ids_to_model_objects(item_ids, result_type)
  end
  
  def search_item_compound_ids_to_objects(item_compound_ids)
    BioCatalogue::Mapper.compound_ids_to_model_objects(item_compound_ids)
  end
  
end
