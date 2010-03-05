# BioCatalogue: app/views/api/filtering/_filters.xml.builder
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

filter_groups = @filter_groups unless local_assigns.has_key?(:filter_groups)

# <filters>

parent_xml.tag! "filters", 
                xlink_attributes(uri_for_collection("#{resource_type}/filters", :params => params)), 
                xml_root_attributes, 
                :for => resource_type,
                :resourceType => "Filters" do
  
  # <group> *
  filter_groups.each do |g|
    parent_xml.group :name => g.name do
      
      # <type> *
      g.filter_types.each do |t|
        parent_xml.type :name => t.name, :description => t.description, :urlKey => t.key do
          
          # <filter> *
          xml_for_filters(parent_xml, t.filters, t.key, resource_type)
          
        end
      end
      
    end
  end
  
end