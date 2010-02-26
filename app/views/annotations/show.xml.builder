# BioCatalogue: app/views/annotations/show.xml.builder
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# <?xml>
xml.instruct! :xml

# <annotation>
render :partial => "annotations/api/annotation", 
       :locals => { :parent_xml => xml,
                    :annotation => @annotation,
                    :is_root => true,
                    :show_annotatable => true,
                    :show_source => true,
                    :show_related => true }
