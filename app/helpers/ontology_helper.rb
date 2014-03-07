module OntologyHelper
  ONTOLOGIES = ['swo_license', 'edam_topic']

  def attributes_for_ontologies
    return AnnotationAttribute.find_all_by_name(ONTOLOGIES)
  end

  def edam_hierachy_text(edam_topic)
  end

  def remove_formatting_of ontology_concept
    return '' if ontology_concept.nil?
    return ontology_concept.gsub('--', '').strip
  end

  def ontology_select_tag form,type,element_id,selected_uri,html_options={}
    reader = reader_for_type(type)
    classes = reader.class_hierarchy
    options = render_ontology_class_options classes
    form.select element_id,options,{:selected=>selected_uri},html_options
  end

  def render_ontology_class_options clz,depth=0
    result = [["--"*depth+clz.label]]
    clz.subclasses.each do |c|
      result += render_ontology_class_options(c,depth+1)
    end
    result
  end

  def get_edam_id(uri)
    /\d*$/.match(uri).to_a.last
  end

  def reader_for_type type
    "BioCatalogue::Ontologies::#{type.capitalize}Reader".constantize.instance
  end

end