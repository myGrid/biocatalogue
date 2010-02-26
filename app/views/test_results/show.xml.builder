# BioCatalogue: app/views/test_results/show.xml.builder
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# <?xml>
xml.instruct! :xml

# <serviceTest>
render :partial => "test_results/api/test_result", 
       :locals => { :parent_xml => xml,
                    :test_result => @test_result,
                    :is_root => true,
                    :show_ancestors => true,
                    :show_related => true }
