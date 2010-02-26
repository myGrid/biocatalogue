# BioCatalogue: app/views/service_tests/api/_inline_item.xml.builder
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# <serviceTest>
render :partial => "service_tests/api/service_test", 
       :locals => { :parent_xml => parent_xml,
                    :service_test => service_test,
                    :is_root => false,
                    :show_latest_status => true,
                    :show_ancestors => false,
                    :show_related => false }