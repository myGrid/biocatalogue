# BioCatalogue: app/views/users/api/_saved_searches.xml.builder
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# <savedSearches>
parent_xml.savedSearches xlink_attributes(uri_for_object(user, :sub_path => "saved_searches"), 
                                          :title => xlink_title("This User's saved searches")), 
                         :resourceType => "User" do |saved_searches_node|  
                  
  user.saved_searches.each do |saved_search|
    # <savedSearch>
    render :partial => "saved_searches/api/inline_item", :locals => { :parent_xml => saved_searches_node, 
                                                                      :saved_search => saved_search }
  end
  
end
