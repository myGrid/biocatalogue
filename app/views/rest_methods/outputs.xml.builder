# BioCatalogue: app/views/rest_methods/outputs.xml.builder
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# <?xml>
xml.instruct! :xml

# <restMethod>
render :partial => "rest_methods/api/rest_method", 
       :locals => { :parent_xml => xml,
                    :rest_method => @rest_method,
                    :is_root => true,
                    :show_inputs => false,
                    :show_ouputs => true,
                    :show_ancestors => false,
                    :show_related => true }
