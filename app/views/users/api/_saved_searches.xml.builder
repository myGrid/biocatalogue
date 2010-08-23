# BioCatalogue: app/views/users/api/_saved_searches.xml.builder
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# <savedSearches>
parent_xml.savedSearches do |node|
                  
  user.saved_searches.each do |saved_search|
    # <savedSearch>
    render :partial => "saved_searches/api/inline_item", :locals => { :parent_xml => node, :saved_search => saved_search }
  end
  
end
