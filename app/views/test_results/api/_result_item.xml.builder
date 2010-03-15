# BioCatalogue: app/views/test_results/api/_result_item.xml.builder
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# <serviceTest>
render :partial => "test_results/api/test_result", 
       :locals => { :parent_xml => parent_xml,
                    :test_result => test_result,
                    :is_root => false,
                    :show_ancestors => true,
                    :show_related => true }