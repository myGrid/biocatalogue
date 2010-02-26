# BioCatalogue: app/views/api/sorting/_parameters.xml.builder
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# <sortBy>
parent_xml.sortBy display_text_for_sort_by(sort_by), :urlKey => "sort_by", :urlValue => sort_by

# <sortOrder>
parent_xml.sortOrder display_text_for_sort_order(sort_order), :urlKey => "sort_order", :urlValue => sort_order
