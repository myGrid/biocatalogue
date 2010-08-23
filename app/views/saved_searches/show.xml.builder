# BioCatalogue: app/views/saved_searches/show.xml.builder
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# <?xml>
xml.instruct! :xml

# <savedSearch>
render :partial => "saved_searches/api/saved_search", 
       :locals => { :parent_xml => xml,
                    :saved_search => @saved_search,
                    :is_root => true }
