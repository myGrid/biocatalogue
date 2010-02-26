# BioCatalogue: app/views/annotations/api/_annotation.xml.builder
#
# Copyright (c) 2009-2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# Defaults:
is_root = false unless local_assigns.has_key?(:is_root)
show_core = true unless local_assigns.has_key?(:show_core)
show_annotatable = true unless local_assigns.has_key?(:show_annotatable)
show_source = true unless local_assigns.has_key?(:show_source)
show_related = false unless local_assigns.has_key?(:show_related)

# <annotation>
parent_xml.tag! "annotation", 
                xlink_attributes(uri_for_object(annotation)).merge(is_root ? xml_root_attributes : {}), 
                :resourceType => "Annotation" do 
  
  if show_annotatable
    
    # <annotatable>
    parent_xml.annotatable xlink_attributes(uri_for_object(annotation.annotatable), :title => "The thing that this annotation is about"),
                           :resourceName => display_name(annotation.annotatable, false),
                           :resourceType => annotation.annotatable_type
  
  end
  
  if show_source
    
    # <source>
    parent_xml.source xlink_attributes(uri_for_object(annotation.source), :title => "The source of this annotation (i.e.: the person, registry, etc that this annotation came from)."),
                      :resourceName => display_name(annotation.source, false),
                      :resourceType => annotation.source_type
    
  end
  
  if show_core
    
    # <version>
    parent_xml.version annotation.version
    
    # <annotationAttribute>
    render :partial => "annotation_attributes/api/annotation_attribute", :locals => { :parent_xml => parent_xml, :annotation_attribute => annotation.attribute }
    
    # <value>
    parent_xml.value do
      
      value_hash = annotation.value_hash
      
      # <resource>
      unless value_hash['resource'].nil?
        parent_xml.resource xlink_attributes(value_hash['resource'], :title => "The resource (if any) that the value of this annotation refers to"),
                            :resourceName => value_hash['content'],
                            :resourceType => value_hash['type']
      end
      
      # <type>
      parent_xml.type value_hash['type']
      
      # <content>
      parent_xml.content value_hash['content']
      
    end
    
    # <dcterms:created>
    dcterms_xml_tag parent_xml, :created, annotation.created_at
    
    # <dcterms:modified>
    unless annotation.created_at == annotation.updated_at
      dcterms_xml_tag parent_xml, :modified, annotation.updated_at
    end
    
  end

  if show_related
    parent_xml.related nil
  end

end