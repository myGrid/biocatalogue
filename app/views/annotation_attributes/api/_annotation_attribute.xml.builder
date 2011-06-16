# BioCatalogue: app/views/annotation_attributes/api/_annotation_attribute.xml.builder
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# Defaults:
is_root = false unless local_assigns.has_key?(:is_root)
show_core = true unless local_assigns.has_key?(:show_core)
show_related = false unless local_assigns.has_key?(:show_related)

# <annotationAttribute>
parent_xml.tag! "annotationAttribute", 
                xlink_attributes(uri_for_object(annotation_attribute)).merge(is_root ? xml_root_attributes : {}), 
                :resourceName => annotation_attribute.name,
                :resourceType => "AnnotationAttribute" do 
  
  if show_core
    
    # <dc:title>
    dc_xml_tag parent_xml, :title, "Annotation Attribute - #{annotation_attribute.identifier}"
    
    # <name>
    parent_xml.name annotation_attribute.name
    
    # <dc:identifier>
    dc_xml_tag parent_xml, :identifier, annotation_attribute.identifier 
    
  end

  if show_related
    parent_xml.related do
      
      # <annotations>
      parent_xml.annotations xlink_attributes(uri_for_object(annotation_attribute, :sub_path => "annotations"), :title => xlink_title("All annotations for the attribute '#{annotation_attribute.identifier}'")),
        :resourceType => "Annotations"
      
    end
  end

end