# BioCatalogue: app/views/services/bmbs.xml.builder
#
# Copyright (c) 2009-2013, University of Manchester, The European Bioinformatics
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details


# <?xml>
xml.instruct! :xml

# <Tools>
xml.tag! "Tools" do
  @services.each_with_index do |service, index|
    xml.tag! "Tool", :toolid => "#{1000 + index}" do
      xml.tag! "ToolName", "#{service.name}\##{service.service.service_deployments.first.endpoint}"
      xml.tag! "Homepage", service.documentation_url
      xml.tag! "Type", "Service"
      categories = service.service.annotations.select { |ann| ann.value_type == "Category" }.collect { |cat| cat.value.name }
      xml.tag! "Topics" do
        categories.each do |category|
          xml.tag! "Topic", map_categories_to_edam_topics(category)
        end
      end
      #xml.tag! " #{SITE_NAME.camelize}URL", service_url(service.service)
      xml.tag! "Description", service.service.description ? service.description[0..200] : ""
      xml.tag! "Functions" do
        categories.each do |category|
          xml.tag! "Function", map_categories_to_edam_operations(category)
        end
      end
      xml.tag! "Interfaces", service.is_a?(RestService) ? "REST API" : "SOAP API"
      xml.tag! "DocsEntry", service.documentation_url
      xml.tag! "WSDL", service.try(:wsdl_location)
      xml.tag! "Helpdesk", ""
      xml.tag! "Source", "BioCatalogue"
      #inputType
      #outputType
    end
  end
end

def map_categories_to_edam_topics topic
  case topic
    when 'Protein Sequence Analysis'
      return {:name => 'Protein sequence analysis', :uri => 'http://edamontology.org/topic_0639'}
    when 'Function Prediction'
      return {:name => 'Protein function prediction', :uri => 'http://edamontology.org/topic_2276'}
    when 'Protein Structure Prediction'
      return {:name => 'Protein structure prediction', :uri => 'http://edamontology.org/topic_0172'}
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
    when 'Data Retrieval'
      return {:name => 'Data search and retrieval', :uri => 'http://edamontology.org/topic_0090'}
    when 'Document Clustering'
      return {:name => 'Literature analysis', :uri => 'http://edamontology.org/topic_0217'}
    when 'Document Discovery'
      return {:name => 'Literature analysis', :uri => 'http://edamontology.org/topic_0217'}
    when 'Document Similarity'
      return {:name => 'Literature analysis', :uri => 'http://edamontology.org/topic_0217'}
    when 'Domains'
      return {:name => 'Protein domains and folds', :uri => 'http://edamontology.org/topic_0736'}
    when 'Evolutionary Distance Measurements'
      return {:name => 'Phylogeny reconstruction', :uri => 'http://edamontology.org/topic_0191'}
    when 'Functional Genomics'
      return {:name => 'Functional genomics', :uri => 'http://edamontology.org/topic_0085'}
    when 'Gene Prediction'
      return {:name => 'Gene finding', :uri => 'http://edamontology.org/topic_0109'}
    when 'Genome Annotation'
      return {:name => 'Annotation', :uri => 'http://edamontology.org/topic_0219'}
    when 'Genomics'
      return {:name => 'Genomics', :uri => 'http://edamontology.org/topic_0622'}
    when 'Identifier Retrieval'
      return {:name => 'Data search and retrieval', :uri => 'http://edamontology.org/topic_0090'}
    when 'Image Retrieval'
      return {:name => 'Data search and retrieval', :uri => 'http://edamontology.org/topic_0090'}
    when 'Ligand Interaction'
      return {:name => 'Protein-ligand interactions', :uri => 'http://edamontology.org/topic_0148'}
    when 'Literature retrieval'
      return {:name => 'Literature analysis', :uri => 'http://edamontology.org/topic_0217'}
    when 'Microarrays'
      return {:name => 'Microarrays', :uri => 'http://edamontology.org/topic_0200'}
    when 'Model Analysis'
      return {:name => 'Systems biology', :uri => 'http://edamontology.org/topic_2259'}
    when 'Model Creation'
      return {:name => 'Systems biology', :uri => 'http://edamontology.org/topic_2259'}
    when 'Model Execution'
      return {:name => 'Systems biology', :uri => 'http://edamontology.org/topic_2259'}
    when 'Motifs'
      return {:name => 'Sequence motifs', :uri => 'http://edamontology.org/topic_0158'}
    when 'Named Entity Recognition'
      return {:name => 'Literature analysis', :uri => 'http://edamontology.org/topic_0217'}
    when 'Nucleotide Multiple Alignment'
      return {:name => 'Sequence alignment', :uri => 'http://edamontology.org/topic_0182'}
    when 'Nucleotide Pairwise Alignment'
      return {:name => 'Sequence alignment', :uri => 'http://edamontology.org/topic_0182'}
    when 'Nucleotide Secondary Structure'
      return {:name => 'Nucleic acid structure analysis', :uri => 'http://edamontology.org/topic_0097'}
    when 'Nucleotide Sequence Alignment'
      return {:name => 'Sequence alignment', :uri => 'http://edamontology.org/topic_0182'}
    when 'Nucleotide Sequence Analysis'
      return {:name => 'Nucleic acid sequence analysis', :uri => 'http://edamontology.org/topic_0640'}
    when 'Nucleotide Sequence Similarity'
      return {:name => 'Sequence comparison', :uri => 'http://edamontology.org/topic_0159'}
    when 'Nucleotide Structure Prediction'
      return {:name => 'Nucleic acid structure prediction', :uri => 'http://edamontology.org/topic_0173'}
    when 'Nucleotide Tertiary Structure'
      return {:name => 'Nucleic acid structure analysis', :uri => 'http://edamontology.org/topic_0097'}
    when 'Ontology'
      return {:name => 'Ontology', :uri => 'http://edamontology.org/topic_0089'}
    when 'Ontology Annotation'
      return {:name => 'Annotation', :uri => 'http://edamontology.org/topic_0219'}
    when 'Ontology Lookup'
      return {:name => 'Data search and retrieval', :uri => 'http://edamontology.org/topic_0090'}
    when 'Pathway Retrieval'
      return {:name => 'Data search and retrieval', :uri => 'http://edamontology.org/topic_0090'}
    when 'Pathways'
      return {:name => 'Pathways, networks and models', :uri => 'http://edamontology.org/topic_0602'}
    when 'Phylogeny'
      return {:name => 'Phylogenetics', :uri => 'http://edamontology.org/topic_0084'}
    when 'Promoter Prediction'
      return {:name => 'Transcription factors and regulatory sites', :uri => 'http://edamontology.org/topic_0749'}
    when 'Protein Multiple Alignment'
      return {:name => 'Sequence alignment', :uri => 'http://edamontology.org/topic_0182'}
    when 'Protein Pairwise Alignment'
      return {:name => 'Sequence alignment', :uri => 'http://edamontology.org/topic_0182'}
    when 'Protein Secondary Structure'
      return {:name => 'Protein secondary structure', :uri => 'http://edamontology.org/topic_0694'}
    when 'Protein Sequence Alignment'
      return {:name => 'Sequence alignment', :uri => 'http://edamontology.org/topic_0182'}
    when 'Protein Sequence Similarity'
      return {:name => 'Sequence comparison', :uri => 'http://edamontology.org/topic_0159'}
    when 'Protein Tertiary Structure'
      return {:name => 'Protein structure analysis', :uri => 'http://edamontology.org/topic_2814'}
    when 'Proteomics'
      return {:name => 'Proteomics', :uri => 'http://edamontology.org/topic_0121'}
    when 'Repeats'
      return {:name => 'Repeat sequences', :uri => 'http://edamontology.org/topic_0641'}
    when 'Sequence Retrieval'
      return {:name => 'Data search and retrieval', :uri => 'http://edamontology.org/topic_0090'}
    when 'Statistical Robustness'
      return {:name => 'Phylogenetics', :uri => 'http://edamontology.org/topic_0084'}
    when 'Structural Genomics'
      return {:name => 'Structural genomics', :uri => 'http://edamontology.org/topic_0122'}
    when 'Structure Retrieval'
      return {:name => 'Data search and retrieval', :uri => 'http://edamontology.org/topic_0090'}
    when 'Systems Biology'
      return {:name => 'Systems biology', :uri => 'http://edamontology.org/topic_2259'}
    when 'Text Mining'
      return {:name => 'Text mining', :uri => 'http://edamontology.org/topic_0218'}
    when 'Transcription Factors'
      return {:name => 'Transcription factors and regulatory sites', :uri => 'http://edamontology.org/topic_0749'}
    when 'Tree Display'
      return {:name => 'Phylogenetics', :uri => 'http://edamontology.org/topic_0084'}
    when 'Tree Inference'
      return {:name => 'Phylogeny reconstruction', :uri => 'http://edamontology.org/topic_0191'}
    else
      return {:name => topic, :uri => ''}
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
    when 'Protein Interaction'
      return {:name => '', :uri => ''}
    when 'Sequence Analysis'
      return {:name => 'Sequence analysis', :uri => 'http://edamontology.org/operation_2403'}
    when 'Biostatistics'
      return {:name => '', :uri => ''}
    when 'Chemoinformatics'
      return {:name => '', :uri => ''}
    when 'Comparative Genomics'
      return {:name => '', :uri => ''}
    when 'Data Retrieval'
      return {:name => 'Data retrieval', :uri => 'http://edamontology.org/operation_2422'}
    when 'Document Clustering'
      return {:name => '', :uri => ''}
    when 'Document Discovery'
      return {:name => 'Literature search', :uri => 'http://edamontology.org/operation_0305'}
    when 'Document Similarity'
      return {:name => '', :uri => ''}
    when 'Domains'
      return {:name => '', :uri => ''}
    when 'Evolutionary Distance Measurements'
      return {:name => 'Phylogenetic tree construction (minimum distance methods)', :uri => 'http://edamontology.org/operation_0546'}
    when 'Functional Genomics'
      return {:name => '', :uri => ''}
    when 'Gene Prediction'
      return {:name => 'Gene and gene component prediction', :uri => 'http://edamontology.org/operation_2454'}
    when 'Genome Annotation'
      return {:name => 'Genome annotation', :uri => 'http://edamontology.org/operation_0362'}
    when 'Genomics'
      return {:name => '', :uri => ''}
    when 'Identifier Retrieval'
      return {:name => 'Data retrieval (metadata and documentation)', :uri => 'http://edamontology.org/operation_0304'}
    when 'Image Retrieval'
      return {:name => 'Data retrieval', :uri => 'http://edamontology.org/operation_2422'}
    when 'Ligand Interaction'
      return {:name => '', :uri => ''}
    when 'Literature retrieval'
      return {:name => 'Literature search', :uri => 'http://edamontology.org/operation_0305'}
    when 'Microarrays'
      return {:name => '', :uri => ''}
    when 'Model Analysis'
      return {:name => '', :uri => ''}
    when 'Model Creation'
      return {:name => '', :uri => ''}
    when 'Model Execution'
      return {:name => '', :uri => ''}
    when 'Motifs'
      return {:name => '', :uri => ''}
    when 'Named Entity Recognition'
      return {:name => '', :uri => ''}
    when 'Nucleotide Multiple Alignment'
      return {:name => 'Multiple sequence alignment construction', :uri => 'http://edamontology.org/operation_0492'}
    when 'Nucleotide Pairwise Alignment'
      return {:name => 'Pairwise sequence alignment construction', :uri => 'http://edamontology.org/operation_0491'}
    when 'Nucleotide Secondary Structure'
      return {:name => 'RNA secondary structure prediction', :uri => 'http://edamontology.org/operation_0278'}
    when 'Nucleotide Sequence Alignment'
      return {:name => '', :uri => ''}
    when 'Nucleotide Sequence Analysis'
      return {:name => 'Nucleic acid sequence analysis', :uri => 'http://edamontology.org/operation_2478'}
    when 'Nucleotide Sequence Similarity'
      return {:name => 'Nucleic acid sequence comparison', :uri => 'http://edamontology.org/operation_2508'}
    when 'Nucleotide Structure Prediction'
      return {:name => 'Nucleic acid structure prediction', :uri => 'http://edamontology.org/operation_0475'}
    when 'Nucleotide Tertiary Structure'
      return {:name => 'Nucleic acid structure prediction', :uri => 'http://edamontology.org/operation_0475'}
    when 'Ontology'
      return {:name => '', :uri => ''}
    when 'Ontology Annotation'
      return {:name => '', :uri => ''}
    when 'Ontology Lookup'
      return {:name => 'Data retrieval', :uri => 'http://edamontology.org/operation_2422'}
    when 'Pathway Retrieval'
      return {:name => 'Data retrieval', :uri => 'http://edamontology.org/operation_2422'}
    when 'Pathways'
      return {:name => '', :uri => ''}
    when 'Phylogeny'
      return {:name => '', :uri => ''}
    when 'Promoter Prediction'
      return {:name => 'Promoter prediction', :uri => 'http://edamontology.org/operation_0440'}
    when 'Protein Multiple Alignment'
      return {:name => 'Multiple sequence alignment construction', :uri => 'http://edamontology.org/operation_0492'}
    when 'Protein Pairwise Alignment'
      return {:name => 'Pairwise sequence alignment construction', :uri => 'http://edamontology.org/operation_0491'}
    when 'Protein Secondary Structure'
      return {:name => 'Protein secondary structure prediction', :uri => 'http://edamontology.org/operation_0267'}
    when 'Protein Sequence Alignment'
      return {:name => '', :uri => ''}
    when 'Protein Sequence Similarity'
      return {:name => 'Protein sequence comparison', :uri => 'http://edamontology.org/operation_2509'}
    when 'Protein Tertiary Structure'
      return {:name => 'Protein structure analysis', :uri => 'http://edamontology.org/operation_2406'}
    when 'Proteomics'
      return {:name => '', :uri => ''}
    when 'Repeats'
      return {:name => '', :uri => ''}
    when 'Sequence Retrieval'
      return {:name => 'Sequence retrieval', :uri => 'http://edamontology.org/operation_1813'}
    when 'Statistical Robustness'
      return {:name => 'Phylogenetic tree analysis', :uri => 'http://edamontology.org/operation_0324'}
    when 'Structural Genomics'
      return {:name => '', :uri => ''}
    when 'Structure Retrieval'
      return {:name => 'Structure retrieval', :uri => 'http://edamontology.org/operation_1814'}
    when 'Systems Biology'
      return {:name => '', :uri => ''}
    when 'Text Mining'
      return {:name => 'Text mining', :uri => 'http://edamontology.org/operation_0306'}
    when 'Transcription Factors'
      return {:name => 'Transcription regulatory element prediction', :uri => 'http://edamontology.org/operation_0438'}
    when 'Tree Display'
      return {:name => 'Phylogenetic tree rendering', :uri => 'http://edamontology.org/operation_0567'}
    when 'Tree Inference'
      return {:name => 'Phylogenetic tree construction', :uri => 'http://edamontology.org/operation_0323'}
    else
      return {:name => topic, :uri => ''}
  end
end

=begin
Specs Given
---
Name
Homepage
Type (always "Service")
Topics (use original values mapping above)
Description
Functions (use mapping resolver above)
Interfaces (one of "REST API" or "SOAP API")
DocsEntry (maybe? - ask Alex / look)
WSDL
Helpdesk (don't think BC have this)
Source (always "BioCatalogue")
=end
