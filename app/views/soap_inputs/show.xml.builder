# BioCatalogue: app/views/soap_inputs/show.xml.builder
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# <?xml>
xml.instruct! :xml

# <soapInput>
render :partial => "soap_inputs/api/soap_input", 
       :locals => { :parent_xml => xml,
                    :soap_input => @soap_input,
                    :is_root => true,
                    :show_ancestors => true,
                    :show_related => true }
