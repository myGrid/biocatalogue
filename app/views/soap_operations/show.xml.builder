# BioCatalogue: app/views/soap_operations/show.xml.builder
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# <?xml>
xml.instruct! :xml

# <soapOperation>
render :partial => "soap_operations/api/soap_operation", 
       :locals => { :parent_xml => xml,
                    :soap_operation => @soap_operation,
                    :is_root => true,
                    :show_inputs => true,
                    :show_outputs => true,
                    :show_ancestors => true,
                    :show_related => true }
