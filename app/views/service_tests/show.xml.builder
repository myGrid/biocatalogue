# BioCatalogue: app/views/service_tests/show.xml.builder
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# <?xml>
xml.instruct! :xml

# <serviceTest>
render :partial => "service_tests/api/service_test", 
       :locals => { :parent_xml => xml,
                    :service_test => @service_test,
                    :is_root => true,
                    :show_latest_status => true,
                    :show_ancestors => true,
                    :show_related => true }
