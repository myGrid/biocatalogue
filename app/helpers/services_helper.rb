# BioCatalogue: app/helpers/services_helper.rb
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.

module ServicesHelper
  def metadata_counts_for_service(service)
    BioCatalogue::Annotations.metadata_counts_for_service(service)
  end
  
  def total_number_of_annotations_for_service(service, source_type="all")
    BioCatalogue::Annotations.total_number_of_annotations_for_service(service, source_type)
  end
  
  def all_alternative_name_annotations_for_service(service)
    BioCatalogue::Annotations.annotations_for_service_by_attribute(service, "alternative_name")
  end
  
  def service_type_badges(service_types)
    html = ''

    unless service_types.blank?
      service_types.each do |s_type|
        if s_type == "Soaplab"
          html << content_tag(:span, s_type, :class => "service_type_badge_special", :style => "vertical-align: middle; margin-left: 1.5em;")
        else
          html << link_to(s_type, services_path(:t => "[#{s_type}]"), :class => "service_type_badge", :style => "vertical-align: middle; margin-left: 1.5em;")  
        end
      end
    end

    return html
  end

  def service_location_flags(service)
    return '' if service.nil?

    html = ''

    service.service_deployments.each do |s_d|
      unless s_d.country.blank?
        html << link_to(flag_icon_from_country(s_d.country, :text => s_d.location, :style => 'vertical-align: middle; margin-left: 0.5em;'), 
                        services_path(:c => "[#{s_d.country}]"), 
                        :class => "service_location_flag")
      end
    end

    return html
  end
  
  def render_computational_type_details(details_hash)
    return ''.html_safe if details_hash.blank?
    return details_hash.to_s.html_safe if (!details_hash.is_a?(Hash) and !details_hash.is_a?(Array))
    
    #logger.info("computational type details class = #{details_hash.class.name}")

    # When using old WSDLUtils WSDL parser, the computational details about message types were represented in a slightly different hash
    #return render_computational_type_details_entries([ details_hash['type'] ].flatten)
    begin
      return render_computational_type_details_entries_new(details_hash)
    rescue TypeError => err
       # Try to render the hash the old way - probably it contains the data formatted in the old-style hash
      # used before we switched to the new WSDL parser that somehow did not get updated after the switch
       return render_computational_type_details_entries([ details_hash['type'] ].flatten)
    end

  end
  
  # Only services that have an associated soaplab server
  # are updated.
  def render_description_from_soaplab(soap_service)
    if soap_service.soaplab_service?
      from_hash_to_html(soap_service.description_from_soaplab)
    end
  end
  
  def render_description_from_soaplab_snippet(soap_service)
    if soap_service.soaplab_service?
      from_hash_to_html(soap_service.description_from_soaplab, 3)
    end
  end


  def map_categories_to_edam_topics topic
    case topic
      when 'Protein Sequence Analysis'
        return {:name => 'Sequence analysis', :uri => 'http://edamontology.org/topic_0080'}
      when 'Function Prediction'
        return {:name => 'Function analysis', :uri => 'http://edamontology.org/topic_1775'}
      when 'Protein Structure Prediction'
        return {:name => 'Protein structure prediction', :uri => 'http://edamontology.org/topic_0172'}
      when 'Information'
        return {:name => 'Data management', :uri => 'http://edamontology.org/topic_3071'}
      when 'Protein Interaction'
        return {:name => 'Protein interactions', :uri => 'http://edamontology.org/topic_0128'}
      when 'Sequence Analysis'
        return {:name => 'Sequence analysis', :uri => 'http://edamontology.org/topic_0080'}
      when 'Biostatistics'
        return {:name => 'Biostatistics', :uri => 'http://edamontology.org/topic_2269'}
      when 'Chemoinformatics'
        return {:name => 'Chemoinformatics', :uri => 'http://edamontology.org/topic_2258'}
      when 'Comparative Genomics'
        return {:name => 'Comparative genomics', :uri => 'http://edamontology.org/topic_0797'}
      when 'Data Editing'
        return {:name => 'Data management', :uri => 'http://edamontology.org/topic_3071'}
      when 'Data Extraction'
        return {:name => 'Data search, query and retrieval', :uri => 'http://edamontology.org/topic_0090'}
      when 'Data Retrieval'
        return {:name => 'Data search, query and retrieval', :uri => 'http://edamontology.org/topic_0090'}
      when 'Display Data'
        return {:name => 'Data visualisation', :uri => 'http://edamontology.org/topic_0092'}
      when 'Document Clustering'
        return {:name => 'Data mining', :uri => 'http://edamontology.org/topic_0218'}
      when 'Document Discovery'
        return {:name => 'Data mining', :uri => 'http://edamontology.org/topic_0218'}
      when 'Document Similarity'
        return {:name => 'Data mining', :uri => 'http://edamontology.org/topic_0218'}
      when 'Domains'
        return {:name => 'Protein domains and folds', :uri => 'http://edamontology.org/topic_0736'}
      when 'Enzyme kinetics'
        return {:name => 'Enzymes', :uri => 'http://edamontology.org/topic_0821'}
      when 'Evolutionary Distance Measurements'
        return {:name => 'Phylogenetics', :uri => 'http://edamontology.org/topic_3293'}
      when 'Feature Tables'
        return {:name => 'Sequence sites, features and motifs', :uri => 'http://edamontology.org/topic_0160'}
      when 'Functional Genomics'
        return {:name => 'Functional genomics', :uri => 'http://edamontology.org/topic_0085'}
      when 'Gene Expression'
        return {:name => 'Gene expression', :uri => 'http://edamontology.org/topic_0203'}
      when 'Gene Prediction'
        return {:name => 'Gene structure', :uri => 'http://edamontology.org/topic_0114'}
      when 'Genetic Variant Analysis'
        return {:name => 'Genetic variation', :uri => 'http://edamontology.org/topic_0199'}
      when 'Genome Annotation'
        return {:name => 'Genomics', :uri => 'http://edamontology.org/topic_0622'}
      when 'Genome Wide Association Study'
        return {:name => 'GWAS study', :uri => 'http://edamontology.org/topic_3517'}
      when 'Genomics'
        return {:name => 'Genomics', :uri => 'http://edamontology.org/topic_0622'}
      when 'Identifier Retrieval'
        return {:name => 'Data search, query and retrieval', :uri => 'http://edamontology.org/topic_0090'}
      when 'Image Retrieval'
        return {:name => 'Data search, query and retrieval', :uri => 'http://edamontology.org/topic_0090'}
      when 'Ligand Interaction'
        return {:name => 'Protein-ligand interactions', :uri => 'http://edamontology.org/topic_3514'}
      when 'Literature retrieval'
        return {:name => 'Literature and reference', :uri => 'http://edamontology.org/topic_3068'}
      when 'Microarrays'
        return {:name => 'Microarray experiment', :uri => 'http://edamontology.org/topic_3518'}
      when 'Model Analysis'
        return {:name => 'Systems biology', :uri => 'http://edamontology.org/topic_2259'}
      when 'Model Creation'
        return {:name => 'Systems biology', :uri => 'http://edamontology.org/topic_2259'}
      when 'Model Execution'
        return {:name => 'Systems biology', :uri => 'http://edamontology.org/topic_2259'}
      when 'Molecular Markers and Mapping Tools'
        return {:name => 'Biomarkers', :uri => 'http://edamontology.org/topic_3360'}
      when 'Motifs'
        return {:name => 'Sequence sites, features and motifs', :uri => 'http://edamontology.org/topic_0160'}
      when 'Named Entity Recognition'
        return {:name => 'Data mining', :uri => 'http://edamontology.org/topic_0218'}
      when 'Nucleic Acid Composition'
        return {:name => 'Sequence composition, complexity and repeats', :uri => 'http://edamontology.org/topic_0157'}
      when 'Nucleic Acid Profiles'
        return {:name => 'Sequence sites, features and motifs', :uri => 'http://edamontology.org/topic_0160'}
      when 'Nucleic Acid Repeats'
        return {:name => 'Nucleic acid repeats', :uri => 'http://edamontology.org/topic_3126'}
      when 'Nucleic Codon Usage'
        return {:name => 'Gene expression', :uri => 'http://edamontology.org/topic_0203'}
      when 'Nucleic CPG Islands'
        return {:name => 'Nucleic acid sites, features and motifs', :uri => 'http://edamontology.org/topic_3511'}
      when 'Nucleic Motifs'
        return {:name => 'Nucleic acid sites, features and motifs', :uri => 'http://edamontology.org/topic_3511'}
      when 'Nucleic Mutation'
        return {:name => 'DNA mutation', :uri => 'http://edamontology.org/topic_2533'}
      when 'Nucleic Sequence Translation'
        return {:name => 'Protein expression', :uri => 'http://edamontology.org/topic_0108'}
      when 'Nucleotide Multiple Alignment'
        return {:name => 'Sequence comparison', :uri => 'http://edamontology.org/topic_0159'}
      when 'Nucleotide Pairwise Alignment'
        return {:name => 'Sequence comparison', :uri => 'http://edamontology.org/topic_0159'}
      when 'Nucleotide Secondary Structure'
        return {:name => 'Nucleic acid structure analysis', :uri => 'http://edamontology.org/topic_0097'}
      when 'Nucleotide Sequence Alignment'
        return {:name => 'Sequence comparison', :uri => 'http://edamontology.org/topic_0159'}
      when 'Nucleotide Sequence Analysis'
        return {:name => 'Nucleic acid sequence analysis', :uri => 'http://edamontology.org/topic_0640'}
      when 'Nucleotide Sequence Similarity'
        return {:name => 'Sequence comparison', :uri => 'http://edamontology.org/topic_0159'}
      when 'Nucleotide Structure Prediction'
        return {:name => 'Nucleic acid structure prediction', :uri => 'http://edamontology.org/topic_0173'}
      when 'Nucleotide Tertiary Structure'
        return {:name => 'Nucleic acid structure analysis', :uri => 'http://edamontology.org/topic_0097'}
      when 'Ontology'
        return {:name => 'Ontology and terminology', :uri => 'http://edamontology.org/topic_0089'}
      when 'Ontology Annotation'
        return {:name => 'Data deposition, annotation and curation', :uri => 'http://edamontology.org/topic_0219'}
      when 'Ontology Lookup'
        return {:name => 'Data search, query and retrieval', :uri => 'http://edamontology.org/topic_0090'}
      when 'Pathway Retrieval'
        return {:name => 'Data search, query and retrieval', :uri => 'http://edamontology.org/topic_0090'}
      when 'Pathways'
        return {:name => 'Molecular interactions, pathways and networks', :uri => 'http://edamontology.org/topic_0602'}
      when 'Phylogeny'
        return {:name => 'Phylogenetics', :uri => 'http://edamontology.org/topic_3293'}
      when 'Primer Design'
        return {:name => 'Primers', :uri => 'http://edamontology.org/topic_0922'}
      when 'Promoter Prediction'
        return {:name => 'Transcription factors and regulatory sites', :uri => 'http://edamontology.org/topic_0749'}
      when 'Protein Composition'
        return {:name => 'Sequence composition, complexity and repeats', :uri => 'http://edamontology.org/topic_0157'}
      when 'Protein Motifs'
        return {:name => 'Sequence sites, features and motifs', :uri => 'http://edamontology.org/topic_0160'}
      when 'Protein Multiple Alignment'
        return {:name => 'Sequence comparison', :uri => 'http://edamontology.org/topic_0159'}
      when 'Protein Mutation'
        return {:name => 'DNA mutation', :uri => 'http://edamontology.org/topic_2533'}
      when 'Protein Pairwise Alignment'
        return {:name => 'Sequence comparison', :uri => 'http://edamontology.org/topic_0159'}
      when 'Protein Profiles'
        return {:name => 'Sequence sites, features and motifs', :uri => 'http://edamontology.org/topic_0160'}
      when 'Protein Secondary Structure'
        return {:name => 'Protein secondary structure', :uri => 'http://edamontology.org/topic_3542'}
      when 'Protein Sequence Alignment'
        return {:name => 'Sequence comparison', :uri => 'http://edamontology.org/topic_0159'}
      when 'Protein Sequence Similarity'
        return {:name => 'Sequence comparison', :uri => 'http://edamontology.org/topic_0159'}
      when 'Protein Tertiary Structure'
        return {:name => 'Protein structure analysis', :uri => 'http://edamontology.org/topic_2814'}
      when 'Proteomics'
        return {:name => 'Proteomics', :uri => 'http://edamontology.org/topic_0121'}
      when 'Repeats'
        return {:name => 'Sequence composition, complexity and repeats', :uri => 'http://edamontology.org/topic_0157'}
      when 'Restriction Enzyme Sites'
        return {:name => 'Enzymes', :uri => 'http://edamontology.org/topic_0821'}
      when 'RNA Analysis'
        return {:name => 'Nucleic acid structure analysis', :uri => 'http://edamontology.org/topic_0097'}
      when 'Sequence Retrieval'
        return {:name => 'Data search, query and retrieval', :uri => 'http://edamontology.org/topic_0090'}
      when 'Statistical Robustness'
        return {:name => 'Data analysis', :uri => 'http://edamontology.org/topic_3365'}
      when 'Structural Genomics'
        return {:name => 'Structural genomics', :uri => 'http://edamontology.org/topic_0122'}
      when 'Structure Retrieval'
        return {:name => 'Data search, query and retrieval', :uri => 'http://edamontology.org/topic_0090'}
      when 'Systems Biology'
        return {:name => 'Systems biology', :uri => 'http://edamontology.org/topic_2259'}
      when 'Text Mining'
        return {:name => 'Data mining', :uri => 'http://edamontology.org/topic_0218'}
      when 'Transcription Factors'
        return {:name => 'Transcription factors and regulatory sites', :uri => 'http://edamontology.org/topic_0749'}
      when 'Tree Display'
        return {:name => 'Phylogenetics', :uri => 'http://edamontology.org/topic_3293'}
      when 'Tree Inference'
        return {:name => 'Phylogenetics', :uri => 'http://edamontology.org/topic_3293'}
      else
        return {}
    end
  end


  def map_categories_to_edam_operations topic
    case topic
      when 'Protein Sequence Analysis'
        return {:name => 'Protein sequence analysis', :uri => 'http://edamontology.org/operation_2479'}
      when 'Function Prediction'
        return {:name => 'Protein function prediction', :uri => 'http://edamontology.org/operation_1777'}
      when 'Protein Structure Prediction'
        return {:name => 'Protein structure prediction', :uri => 'http://edamontology.org/operation_0474'}
      when 'Sequence Analysis'
        return {:name => 'Sequence analysis', :uri => 'http://edamontology.org/operation_2403'}
      when 'Data Editing'
        return {:name => 'Editing', :uri => 'http://edamontology.org/operation_3096'}
      when 'Data Extraction'
        return {:name => 'Data retrieval', :uri => 'http://edamontology.org/operation_2422'}
      when 'Data Retrieval'
        return {:name => 'Data retrieval', :uri => 'http://edamontology.org/operation_2422'}
      when 'Display Data'
        return {:name => 'Visualisation', :uri => 'http://edamontology.org/operation_0337'}
      when 'Document Discovery'
        return {:name => 'Literature search', :uri => 'http://edamontology.org/operation_0305'}
      when 'Evolutionary Distance Measurements'
        return {:name => 'Phylogenetic tree construction (minimum distance methods)', :uri => 'http://edamontology.org/operation_0546'}
      when 'Gene Expression'
        return {:name => 'Gene expression data analysis', :uri => 'http://edamontology.org/operation_2495'}
      when 'Gene Prediction'
        return {:name => 'Gene prediction', :uri => 'http://edamontology.org/operation_2454'}
      when 'Genetic Variant Analysis'
        return {:name => 'Genetic variation analysis', :uri => 'http://edamontology.org/operation_3197'}
      when 'Genome Annotation'
        return {:name => 'Genome annotation', :uri => 'http://edamontology.org/operation_0362'}
      when 'Identifier Retrieval'
        return {:name => 'Metadata retrieval', :uri => 'http://edamontology.org/operation_0304'}
      when 'Image Retrieval'
        return {:name => 'Data retrieval', :uri => 'http://edamontology.org/operation_2422'}
      when 'Literature retrieval'
        return {:name => 'Literature search', :uri => 'http://edamontology.org/operation_0305'}
      when 'Nucleic Acid Composition'
        return {:name => 'Sequence composition calculation', :uri => 'http://edamontology.org/operation_0236'}
      when 'Nucleotide Multiple Alignment'
        return {:name => 'Multiple sequence alignment', :uri => 'http://edamontology.org/operation_0492'}
      when 'Nucleotide Pairwise Alignment'
        return {:name => 'Pairwise sequence alignment', :uri => 'http://edamontology.org/operation_0491'}
      when 'Nucleotide Secondary Structure'
        return {:name => 'RNA secondary structure prediction', :uri => 'http://edamontology.org/operation_0278'}
      when 'Nucleotide Sequence Alignment'
        return {:name => 'Multiple sequence alignment', :uri => 'http://edamontology.org/operation_0492'}
      when 'Nucleotide Sequence Analysis'
        return {:name => 'Nucleic acid sequence analysis', :uri => 'http://edamontology.org/operation_2478'}
      when 'Nucleotide Sequence Similarity'
        return {:name => 'Nucleic acid sequence comparison', :uri => 'http://edamontology.org/operation_2508'}
      when 'Nucleotide Structure Prediction'
        return {:name => 'Nucleic acid structure prediction', :uri => 'http://edamontology.org/operation_0475'}
      when 'Nucleotide Tertiary Structure'
        return {:name => 'Nucleic acid structure prediction', :uri => 'http://edamontology.org/operation_2481'}
      when 'Ontology Annotation'
        return {:name => 'Annotation', :uri => 'http://edamontology.org/operation_0226'}
      when 'Ontology Lookup'
        return {:name => 'Data retrieval', :uri => 'http://edamontology.org/operation_2422'}
      when 'Pathway Retrieval'
        return {:name => 'Data retrieval', :uri => 'http://edamontology.org/operation_2422'}
      when 'Primer Design'
        return {:name => 'Primer and probe design', :uri => 'http://edamontology.org/operation_2419'}
      when 'Promoter Prediction'
        return {:name => 'Promoter prediction', :uri => 'http://edamontology.org/operation_0440'}
      when 'Protein Composition'
        return {:name => 'Sequence composition calculation', :uri => 'http://edamontology.org/operation_0236'}
      when 'Protein Multiple Alignment'
        return {:name => 'Multiple sequence alignment', :uri => 'http://edamontology.org/operation_0492'}
      when 'Protein Pairwise Alignment'
        return {:name => 'Pairwise sequence alignment construction', :uri => 'http://edamontology.org/operation_0491'}
      when 'Protein Secondary Structure'
        return {:name => 'Protein secondary structure prediction', :uri => 'http://edamontology.org/operation_0267'}
      when 'Protein Sequence Similarity'
        return {:name => 'Protein sequence comparison', :uri => 'http://edamontology.org/operation_2509'}
      when 'Protein Tertiary Structure'
        return {:name => 'Protein structure analysis', :uri => 'http://edamontology.org/operation_2406'}
      when 'Sequence Retrieval'
        return {:name => 'Data retrieval', :uri => 'http://edamontology.org/operation_2422'}
      when 'Statistical Robustness'
        return {:name => 'Statistical calculation', :uri => 'http://edamontology.org/operation_2238'}
      when 'Structure Retrieval'
        return {:name => 'Data retrieval', :uri => 'http://edamontology.org/operation_2422'}
      when 'Text Mining'
        return {:name => 'Text mining', :uri => 'http://edamontology.org/operation_0306'}
      when 'Transcription Factors'
        return {:name => 'Regulatory element prediction', :uri => 'http://edamontology.org/operation_0438'}
      when 'Tree Display'
        return {:name => 'Phylogenetic tree visualisation', :uri => 'http://edamontology.org/operation_0567'}
      when 'Tree Inference'
        return {:name => 'Phylogenetic tree generation', :uri => 'http://edamontology.org/operation_0323'}
      else
        return {}
    end
  end



  protected
  
  def render_computational_type_details_entries(entries)
    html = ''.html_safe
    
    return html if entries.empty?
    
    html << content_tag(:ul) do
      x = ''.html_safe
      entries.each do |entry|
        x << render_computational_type_details_entry(entry).html_safe
      end
      x.html_safe
    end
    
    return html.html_safe
  end
  
  def render_computational_type_details_entry(entry)
    html = ''.html_safe
    
    return html if entry.blank?
    
    html << content_tag(:li) do
      x = entry['name'].nil? ? ''.html_safe : entry['name'].html_safe
      if entry['documentation']
        x << info_icon_with_tooltip(white_list(simple_format(entry['documentation']))).html_safe
      end
      if entry['type'] and !entry['type'].blank?
        x << content_tag(:span, "type:", :class => "type_keyword").html_safe
        x << render_computational_type_details_entries([ entry['type'] ].flatten).html_safe
      end
      x.html_safe
    end
    
    return html.html_safe
  end


  # Renders a hash like:
  # {
  #   'name' => '...',
  #   'type' => [
  #               {'name' => '...',
  #                'type' => [...]
  #               },
  #               ...
  #             ]
  # }
  def render_computational_type_details_entries_new(computational_type_details_hash)
    html = ''.html_safe

    return html if computational_type_details_hash.blank?
    return html if computational_type_details_hash['name'].blank? && computational_type_details_hash['type'].blank?

    html << content_tag(:ul) do
      render_computational_type_details_entry_new(computational_type_details_hash).html_safe
    end

    return html.html_safe
  end

  def render_computational_type_details_entry_new(entry_hash)
    html = ''.html_safe
    return html if entry_hash.blank?

    html << content_tag(:li) do
      x = entry_hash['name'].blank? ? '' : entry_hash['name']
      if !entry_hash['description'].blank?
        x << info_icon_with_tooltip(white_list(simple_format(entry_hash['description'])))
      end
      if !entry_hash['type'].blank?
        x << content_tag(:span, 'type: ', :class => "type_keyword")
        if entry_hash['type'].is_a?(Array) # it will always be an array or a simple variable - for hashes in original type this will be an array with just one element
          entry_hash['type'].each do |element|
            x << render_computational_type_details_entries_new(element)
          end
        #elsif entry_hash['type'].is_a?(Hash)
        #  x << render_computational_type_details_entries_new(entry_hash['type']).html_safe
        else
          x << entry_hash['type']
        end
      else
        x << ''
      end
      x.html_safe
    end

    return html.html_safe
  end
  
  def get_sorted_list_of_service_ids_from_metadata_counts(service_metadata_counts)
    results = [ ]
    
    return results if service_metadata_counts.blank?
    
    results = service_metadata_counts.keys.sort { |a,b| service_metadata_counts[b][:all] <=> service_metadata_counts[a][:all] }
    
    return results
  end
  

  # convert to an html nested list
  def from_hash_to_html(dict, depth_to_traverse=1000, start_depth=0)
    depth = start_depth
    if dict.is_a?(Hash) && !dict.empty?
      str =''
      str << '<ul>'
      depth += 1
      dict.each do |key, value|
        unless depth > depth_to_traverse
          out = ""
          case value
            when String
              out << value
            when Array
              value.each do |v|
                out << v if v.is_a?(String) 
                out << from_hash_to_html(v, depth_to_traverse, depth) if v.is_a?(Hash)
              end
            end 
          str << "<li> #{key}  : #{ out }</li> "
          if value.is_a?(Hash) 
            str << from_hash_to_html(value, depth_to_traverse, depth)
          end
        end
      end
      str << '</ul> '
      return str
    end
    return ''
  end
  
  def service_tests_for_display(service_tests)

    return service_tests if service_tests.empty?

    service_tests.reject!{|st| st.test_type == "TestScript"} if ENABLE_TEST_SCRIPTS == false

    if logged_in? 
      if !service_tests.first.nil? && !service_tests.first.service.nil?
        return service_tests if (current_user.is_admin? || service_tests.first.service.all_responsibles.include?(current_user))
      end
    end
    
    return service_tests.collect{ |st| st if st.enabled? }.compact
  end
  
end
