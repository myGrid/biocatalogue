# BioCatalogue: app/views/services/index.xml.builder
#
# Copyright (c) 2008-2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

total_count = @services.total_entries
total_pages = @services.total_pages

# <?xml>
xml.instruct! :xml

# <services>
xml.tag! "services", 
         { :resource => BioCatalogue::RestApi::Resources.uri_for_collection("services", :params => params) }, 
         BioCatalogue::RestApi::Builder.root_attributes do
  
  # <parameters>
  xml.parameters do
    
    # <page>
    xml.page @page
    
    # <filters>
    xml.filters do
      
      @current_filters.each do |filter_key, filter_ids|
        
        # <filterType>
        xml.filterType :name => BioCatalogue::Filtering.filter_type_to_display_name(filter_key), :urlKey => filter_key.to_s do
          
          filter_ids.each do |f_id|
            
            # <filter>
            xml.filter :urlValue => f_id,
                       :name => display_name_for_filter(filter_key, f_id)
            
          end
          
        end
        
      end
      
    end
    
    # <query>
    xml.query params[:q]
    
  end
  
  # <statistics>
  xml.statistics do
    
    # <totalPages>
    xml.totalPages total_pages
    
    # <itemCounts>
    xml.itemCounts do 
      
      # <total>
      xml.total total_count      
      
    end
    
  end
  
  # <results>
  xml.results do
    
    # <service> *
    @services.each do |service|
      xml.service :resource => BioCatalogue::RestApi::Resources.uri_for_object(service) do
        # <name>
        xml.name display_name(service)
      end
    end
    
  end
  
  # <related>
  xml.related do
    
    params_clone = BioCatalogue::Util.duplicate_params(params)
    
    # <previous>
    unless @page == 1
      xml.previous :resource => BioCatalogue::RestApi::Resources.uri_for_collection("services", :params => params_clone.update(:page => (@page - 1)))
    end
    
    # <next>
    unless total_pages == 0 or total_pages == @page 
      xml.next :resource => BioCatalogue::RestApi::Resources.uri_for_collection("services", :params => params_clone.update(:page => (@page + 1)))
    end
    
    # <filters>
    xml.filters :resource => BioCatalogue::RestApi::Resources.uri_for_collection("services/filters", :params => params_clone.reject{|k,v| k.to_s.downcase == "page" })
    
  end
  
end