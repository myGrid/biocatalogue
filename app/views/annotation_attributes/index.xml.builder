# BioCatalogue: app/views/annotation_attributes/index.xml.builder
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# <?xml>
xml.instruct! :xml

# <annotationAttributes>
xml.tag! "annotationAttributes", 
         xlink_attributes(uri_for_collection("annotation_attributes", :params => params)), 
         xml_root_attributes,
         :resourceType => "AnnotationAttributes" do
  
  # <parameters>
  xml.parameters do 
    
    # Pagination parameters
    render :partial => "api/pagination/parameters", :locals => { :parent_xml => xml, :page => @page, :per_page => @per_page }
    
  end
  
  # <statistics>
  xml.statistics do
    
    # <pages>
    xml.pages @annotation_attributes.total_pages
    
    # <results>
    xml.results @annotation_attributes.total_entries
    
    # <total>
    xml.total AnnotationAttribute.count
    
  end
  
  # <results>
  xml.results do
    
    # <annotationAttribute> *
    @annotation_attributes.each do |attrib|
      render :partial => "annotation_attributes/api/annotation_attribute", :locals => { :parent_xml => xml, :annotation_attribute => attrib }
    end
    
  end
  
  # <related>
  xml.related do
    
    params_clone = BioCatalogue::Util.duplicate_params(params)
    
    # Pagination previous next links
    render :partial => "api/pagination/previous_next_links", 
           :locals => { :parent_xml => xml,
                        :resource_type => "AnnotationAttributes",
                        :page => @page,
                        :total_pages => @annotation_attributes.total_pages,
                        :params_clone => params_clone,
                        :resource_url_lambda => lambda { |params| uri_for_collection("annotation_attributes", :params => params) } }
    
  end
  
end