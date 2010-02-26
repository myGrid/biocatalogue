# BioCatalogue: app/views/soap_outputs/show.xml.builder
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# <?xml>
xml.instruct! :xml

# <soapOutput>
render :partial => "soap_outputs/api/soap_output", 
       :locals => { :parent_xml => xml,
                    :soap_output => @soap_output,
                    :is_root => true,
                    :show_ancestors => true,
                    :show_related => true }
