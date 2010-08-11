# BioCatalogue: app/views/rest_methods/show.xml.builder
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
                    :show_input_parameters => true,
                    :show_input_representations => true,
                    :show_ouput_representations => true,
                    :show_ancestors => true,
                    :show_related => true }
