# BioCatalogue: app/views/annotation_attributes/show.xml.builder
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# <?xml>
xml.instruct! :xml

# <annotationAttribute>
render :partial => "annotation_attributes/api/annotation_attribute", 
       :locals => { :parent_xml => xml,
                    :annotation_attribute => @annotation_attribute,
                    :is_root => true,
                    :show_related => true }
