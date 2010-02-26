class UpdateAnnotationAttributesIdentifiers < ActiveRecord::Migration
  def self.up
    
    AnnotationAttribute.all.each do |attrib|
      
      if attrib.name.match(/^<.+>$/)
        attrib.identifier = attrib.name[1, attrib.name.length-1].chop
      elsif attrib.name.match(/^http:\/\//) or attrib.name.match(/^urn:/)
        attrib.identifier = attrib.name
      else
        attrib.identifier = case attrib.name.downcase
          when "description"
            "http://purl.org/dc/elements/1.1/description"
          when "format"
            "http://purl.org/dc/elements/1.1/format"
          else
            label = Annotations::Config::attribute_name_transform_for_identifier.call(attrib.name)
            Annotations::Config::default_attribute_identifier_template % label
        end
      end
      
      attrib.save!
      
    end
    
  end

  def self.down
    
    AnnotationAttribute.all.each do |attrib|
      attrib.identifier = nil
      attrib.save(false)
    end
    
  end
end
