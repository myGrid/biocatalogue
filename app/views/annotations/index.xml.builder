# BioCatalogue: app/views/annotations/index.xml.builder
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# <?xml>
xml.instruct! :xml

# <annotations>
xml.tag! "annotations", 
         xlink_attributes(uri_for_collection("annotations", :params => params)), 
         xml_root_attributes,
         :resourceType => "Annotations" do
  
  # <parameters>
  xml.parameters do 
    
    # Filtering parameters
    render :partial => "api/filtering/parameters", :locals => { :parent_xml => xml, :resource_type => "Annotations" }
    
    # Sorting parameters
    render :partial => "api/sorting/parameters", :locals => { :parent_xml => xml, :sort_by => @sort_by, :sort_order => @sort_order }
    
    # Pagination parameters
    render :partial => "api/pagination/parameters", :locals => { :parent_xml => xml, :page => @page, :per_page => @per_page }
    
  end
  
  # <statistics>
  xml.statistics do
    
    # <pages>
    xml.pages @annotations.total_pages
    
    # <results>
    xml.results @annotations.total_entries
    
    # <total>
    xml.total Annotation.count
    
  end
  
  # <results>
  xml.results do
    
    # <annotation> *
    @annotations.each do |ann|
      render :partial => "annotations/api/annotation", :locals => { :parent_xml => xml, :annotation => ann }
    end
    
  end
  
  # <related>
  xml.related do
    
    params_clone = BioCatalogue::Util.duplicate_params(params)
    
    # Pagination previous next links
    render :partial => "api/pagination/previous_next_links", 
           :locals => { :parent_xml => xml,
                        :resource_type => "Annotations",
                        :page => @page,
                        :total_pages => @annotations.total_pages,
                        :params_clone => params_clone,
                        :resource_url_lambda => lambda { |params| uri_for_collection("annotations", :params => params) } }
    
    # <filters>
    xml.filters xlink_attributes(uri_for_collection("annotations/filters"), 
                                 :title => xlink_title("Filters for the annotations index")),
                :resourceType => "Filters"
    
    # <filtersOnCurrentResults>
    xml.filtersOnCurrentResults xlink_attributes(uri_for_collection("annotations/filters", :params => params_clone.reject{|k,v| k.to_s.downcase == "page" }), 
                                 :title => xlink_title("Filters for the annotations index that will be applied on top of the current results set")),
                :resourceType => "Filters"
    
  end
  
end