# BioCatalogue: app/views/test_results/api/_core_elements.xml.builder
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# <testAction>
parent_xml.testAction test_result.action

# <resultCode>
parent_xml.resultCode test_result.result

# <dcterms:created>
dcterms_xml_tag parent_xml, :created, test_result.created_at

# <status>
render :partial => "monitoring/api/status",
       :locals => { :parent_xml => parent_xml, 
                    :element_name => "status", 
                    :status => test_result.status }
