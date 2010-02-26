# BioCatalogue: app/views/api/pagination/_parameters.xml.builder
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# <page>
parent_xml.page page, :urlKey => "page"

# <pageSize>
parent_xml.pageSize per_page, :urlKey => "per_page"