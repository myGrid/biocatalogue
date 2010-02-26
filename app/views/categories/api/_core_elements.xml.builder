# BioCatalogue: app/views/categories/api/_core_elements.xml.builder
#
# Copyright (c) 2009-2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# <dc:title>
dc_xml_tag parent_xml, :title, xlink_title(category)

# <name>
parent_xml.name display_name(category, false)

# <totalItemsCount>
parent_xml.totalItemsCount BioCatalogue::Categorising.number_of_services_for_category(category)