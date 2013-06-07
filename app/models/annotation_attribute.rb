# BioCatalogue: app/models/annotation_attribute.rb
#
# Copyright (c) 2009-2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.

#=====
# This extends the AnnotationAttribute model defined in the Annotations plugin.
#=====

#require_dependency Rails.root.to_s + '/vendor/plugins/annotations/lib/app/models/annotation_attribute'
require_dependency File.join(Gem.loaded_specs['my_annotations'].full_gem_path,'lib','app','models','annotation_attribute')
class AnnotationAttribute < ActiveRecord::Base
#  if ENABLE_CACHE_MONEY
#    is_cached :repository => $cache
#    index [ :name ]
#  end

  def to_json
    generate_json_and_make_inline(false)
  end 
  
  def to_inline_json
    generate_json_and_make_inline(true)
  end

private

  def generate_json_and_make_inline(make_inline)
    data = {
      "annotation_attribute" => {
        "name" => self.name,
        "identifier" => self.identifier
      }
    }

    unless make_inline
      data["annotation_attribute"]["self"] = BioCatalogue::Api.uri_for_object(self)
			return data.to_json
    else
      data["annotation_attribute"]["resource"] = BioCatalogue::Api.uri_for_object(self)
			return data["annotation_attribute"].to_json
    end
  end # generate_json_and_make_inline

end