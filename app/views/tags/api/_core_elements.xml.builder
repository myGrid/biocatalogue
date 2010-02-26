# BioCatalogue: app/views/tags/api/_core_elements.xml.builder
#
# Copyright (c) 2009-2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# <dc:title>
dc_xml_tag parent_xml, :title, xlink_title("Tag - #{tag_name}")

# <name>
parent_xml.name tag_name

# <displayName>
parent_xml.displayName tag_display_name

# <totalItemsCount>
parent_xml.totalItemsCount total_items_count