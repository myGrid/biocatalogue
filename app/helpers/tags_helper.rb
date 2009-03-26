# BioCatalogue: app/helpers/tags_helper.rb
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

module TagsHelper
  # Generates a tag cloud using the provided standardised tags data structure (see /lib/tags.rb for more info).
  def generate_tag_cloud(tags, *args)
    BioCatalogue::Tags.tag_cloud(tags, *args)
  end
  
  # Generates a tag cloud from a list of annotations that are tags. 
  def generate_tag_cloud_from_annotations(tag_annotations, *args)
    generate_tag_cloud(BioCatalogue::Tags.annotations_to_tags_structure(tag_annotations), *args)
  end
end
