# BioCatalogue: app/views/categories/index.xml.builder
#
# Copyright (c) 2009-2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# <?xml>
xml.instruct! :xml

# <categories>
xml.tag! "categories", 
         xlink_attributes(uri_for_collection("categories", :params => params)), 
         xml_root_attributes,
         :resourceType => "Categories" do
  
  # <parameters>
  xml.parameters do 
    
    # <rootsOnly>
    xml.rootsOnly @roots_only, :urlKey => "roots_only"
    
  end
  
  # <statistics>
  xml.statistics do
    
    # <pages>
    xml.pages 1
    
    # <results>
    xml.results (@roots_only ? Category.root_categories.length : Category.count)
    
    # <total>
    xml.total Category.count
    
  end
  
  # <results>
  xml.results do
    
    # <category> *
    
    categories = if @roots_only
      Category.root_categories
    else
      Category.list
    end
    
    categories.each do |cat|
      render :partial => "categories/api/result_item", :locals => { :parent_xml => xml, :category => cat }
    end
    
  end
  
  # <related>
  xml.related do
    
    # <serviceFilters>
    xml.serviceFilters xlink_attributes(uri_for_collection("services/filters", :params => params), 
                                        :title => xlink_title("Filters for the services index, which includes all the category filters.")),
                       :resourceType => "Filters"
    
  end
  
end