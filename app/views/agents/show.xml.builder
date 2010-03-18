# BioCatalogue: app/views/agents/show.xml.builder
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# <?xml>
xml.instruct! :xml

# <agent>
render :partial => "agents/api/agent", 
       :locals => { :parent_xml => xml,
                    :agent => @agent,
                    :is_root => true,
                    :show_related => true }
