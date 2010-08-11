# BioCatalogue: app/views/rest_representations/show.xml.builder
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# <?xml>
xml.instruct! :xml

# <restRepresentation>
render :partial => "rest_representations/api/rest_representation", 
       :locals => { :parent_xml => xml,
                    :rest_representation => @rest_representation,
                    :is_root => true,
                    :show_ancestors => true,
                    :show_related => true }
