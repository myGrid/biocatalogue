# BioCatalogue: app/views/categories/index.xml.builder
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# <?xml>
xml.instruct! :xml

# <filters>
xml.tag! "categories", 
         xlink_attributes(uri_for_collection("categories", :params => params)), 
         xml_root_attributes do
  
  # <parameters>
  xml.parameters
  
  # <statistics>
  xml.statistics do
    
    # <total>
    xml.total Category.count
    
  end
  
  # <results>
  xml.results do
    
    # <category> *
    
    Category.list.each do |cat|
      render :partial => "categories/api/result_item", :locals => { :parent_xml => xml, :category => cat }
    end
    
  end
  
  # <related>
  xml.related do
    
    # <serviceFilters>
    xml.serviceFilters xlink_attributes(uri_for_collection("services/filters", :params => params), 
                                        :title => xlink_title("Filters for the services index"))
    
  end
  
end