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
    items = [ ]
    
    return items if item_ids.blank? or result_type.blank?
    
    model = result_type.classify.constantize
    
    item_ids.each do |item_id|
      item = model.find(:first, :conditions => { :id => item_id })
      items << item unless item.nil?
    end
    
    return items
  end
  
end
