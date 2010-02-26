# BioCatalogue: app/views/soap_outputs/api/_inline_item.xml.builder
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# <soapOutput>
render :partial => "soap_outputs/api/soap_output", 
       :locals => { :parent_xml => parent_xml,
                    :soap_output => soap_output,
                    :show_ancestors => false,
                    :show_related => false }