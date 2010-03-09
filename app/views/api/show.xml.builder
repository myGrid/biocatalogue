# BioCatalogue: app/views/api/show.xml.builder
#
# Copyright (c) 2009-2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# <?xml>
xml.instruct! :xml

# <biocatalogue>
xml.tag! "biocatalogue", 
         xlink_attributes(uri_for_collection("/"), :title => "The BioCatalogue"), 
         xml_root_attributes, 
         :resourceType => "BioCatalogue" do
  
  # <documentation>
  xml.documentation xlink_attributes("http://apidocs.biocatalogue.org", :title => "Documentation for the BioCatalogue APIs")
  
  # <collections>
  xml.collections do
    
    # <search>
    xml.search xlink_attributes(uri_for_collection("search"), :title => xlink_title("Search everything in the BioCatalogue")),
               :resourceType => "Search"
               
    # <services>
    xml.services xlink_attributes(uri_for_collection("services"), :title => xlink_title("Services index")),
                 :resourceType => "Services"
    
    # <soapOperations>
    xml.soapOperations xlink_attributes(uri_for_collection("soap_operations"), :title => xlink_title("SOAP operations index")),
                 :resourceType => "SoapOperations"
    
    # <categories>
    xml.categories xlink_attributes(uri_for_collection("categories"), :title => xlink_title("Categories index")),
                 :resourceType => "Categories"
    
    # <tags>
    xml.tags xlink_attributes(uri_for_collection("tags"), :title => xlink_title("Tags index")),
                 :resourceType => "Tags"
    
    # <annotations>
    xml.annotations xlink_attributes(uri_for_collection("annotations"), :title => xlink_title("Annotations index")),
                 :resourceType => "Annotations"
    
    # <annotationAttributes>
    xml.annotationAttributes xlink_attributes(uri_for_collection("annotation_attributes"), :title => xlink_title("Annotation Attributes index")),
                 :resourceType => "AnnotationAttributes"
    
    # <serviceProviders>
    xml.serviceProviders xlink_attributes(uri_for_collection("service_providers"), :title => xlink_title("Service Providers index")),
                 :resourceType => "ServiceProviders"
                 
    # <users>
    xml.users xlink_attributes(uri_for_collection("users"), :title => xlink_title("Users index")),
                 :resourceType => "Users"
    
    # <registries>
    xml.registries xlink_attributes(uri_for_collection("registries"), :title => xlink_title("Registries index")),
                 :resourceType => "Registries"
    
    # <testResults>
    xml.testResults xlink_attributes(uri_for_collection("test_results"), :title => xlink_title("Test Results index")),
                 :resourceType => "TestResults"
    
    # <filters>
    xml.filters do
      
      # <services>
      xml.services xlink_attributes(uri_for_collection("services/filters"), :title => xlink_title("Filters for the services index")),
                          :resourceType => "Filters"  
      
      # <soapOperations>
      xml.soapOperations xlink_attributes(uri_for_collection("soap_operations/filters"), :title => xlink_title("Filters for the SOAP operations index")),
                          :resourceType => "Filters" 
                          
      # <annotations>
      xml.annotations xlink_attributes(uri_for_collection("annotations/filters"), :title => xlink_title("Filters for the annotations index")),
                          :resourceType => "Filters" 
                          
    end
    
  end
  
end