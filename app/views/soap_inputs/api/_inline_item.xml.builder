# BioCatalogue: app/views/soap_inputs/api/_inline_item.xml.builder
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# <soapInput>
render :partial => "soap_inputs/api/soap_input", 
       :locals => { :parent_xml => parent_xml,
                    :soap_input => soap_input,
                    :show_ancestors => false,
                    :show_related => false }