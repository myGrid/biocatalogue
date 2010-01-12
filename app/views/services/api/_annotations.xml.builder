# BioCatalogue: app/views/services/api/_annotations.xml.builder
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

parent_xml.annotations xlink_attributes(uri_for_object(service, :sub_path => "annotations")) do
  
  annotations_list = BioCatalogue::Annotations.annotations_for_service(service)
  
  BioCatalogue::Annotations.group_by_attribute_names(annotations_list).each do |attribute_name, annotations|
  
    # <annotation> *
    annotations.each do |ann|
      
      parent_xml.annotation xlink_attributes(uri_for_object(ann)), :version => ann.version do 
        
        # <annotatable>
        parent_xml.annotatable xlink_attributes(uri_for_object(ann.annotatable))
        
        # <attribute>
        parent_xml.attribute xlink_attributes(uri_for_object(ann.attribute)),
                             :name => attribute_name
        
        # <value>
        parent_xml.value ann.value, :type => ann.value_type
           
        # <source>
        parent_xml.source xlink_attributes(uri_for_object(ann.source), :title => xlink_title(ann.source)),
                          :sourceType => ann.source_type do
          parent_xml.name ann.source.annotation_source_name
        end
        
        # <created>
        # <modified>
        dcterms_xml_tags(parent_xml, :created => ann.created_at, :modified => ann.updated_at)
        
      end
      
    end
  
  end
  
end