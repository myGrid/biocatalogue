# BioCatalogue: app/views/rest_parameters/show.xml.builder
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# <?xml>
xml.instruct! :xml

# <restParameter>
render :partial => "rest_parameters/api/rest_parameter", 
       :locals => { :parent_xml => xml,
                    :rest_parameter => @rest_parameter,
                    :is_root => true,
                    :show_ancestors => true,
                    :show_related => true }
