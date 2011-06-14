# BioCatalogue: app/views/test_results/api/_ancestors.xml.builder
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# <ancestors>
parent_xml.ancestors do
  
  # <service>
  render :partial => "services/api/inline_item", :locals => { :parent_xml => parent_xml, :service => test_result.service_test.service }
  
  # <serviceTest>
  render :partial => "service_tests/api/inline_item", :locals => { :parent_xml => parent_xml, :service_test => test_result.service_test }
    
end