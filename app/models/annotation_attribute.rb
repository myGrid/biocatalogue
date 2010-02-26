# BioCatalogue: app/models/annotation_attribute.rb
#
# Copyright (c) 2009-2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.

#=====
# This extends the AnnotationAttribute model defined in the Annotations plugin.
#=====

require_dependency RAILS_ROOT + '/vendor/plugins/annotations/lib/app/models/annotation_attribute'

class AnnotationAttribute < ActiveRecord::Base
#  if ENABLE_CACHE_MONEY
#    is_cached :repository => $cache
#    index [ :name ]
#  end

  def to_json
    {
      "annotation_attribute" => {
        "self" => BioCatalogue::Api.uri_for_object(self),
        "name" => self.name,
        "identifier" => self.identifier
      }
    }.to_json
  end
end