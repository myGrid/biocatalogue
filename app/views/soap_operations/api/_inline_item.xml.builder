# BioCatalogue: app/views/soap_operations/api/_inline_item.xml.builder
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# <soapOperation>
render :partial => "soap_operations/api/soap_operation", 
       :locals => { :parent_xml => parent_xml,
                    :soap_operation => soap_operation,
                    :show_inputs => false,
                    :show_outputs => false,
                    :show_ancestors => false,
                    :show_related => false }