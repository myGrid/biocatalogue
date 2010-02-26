# BioCatalogue: app/views/registries/show.xml.builder
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# <?xml>
xml.instruct! :xml

# <registry>
render :partial => "registries/api/registry", 
       :locals => { :parent_xml => xml,
                    :registry => @registry,
                    :is_root => true,
                    :show_related => true }
