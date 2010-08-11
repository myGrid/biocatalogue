# BioCatalogue: app/views/agents/api/_result_item.xml.builder
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# <agent>
render :partial => "agents/api/agent", 
       :locals => { :parent_xml => parent_xml,
                    :agent => agent,
                    :show_related => true }