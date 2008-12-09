class AnnotationValueSeed < ActiveRecord::Base
  validates_presence_of :attribute_id,
                        :value
                        
  def self.find_by_attribute_name(attrib_name)
    return [] if attrib_name.blank?
          
    AnnotationValueSeed.find(:all,
                             :joins => "JOIN annotation_attributes ON annotation_value_seeds.attribute_id = annotation_attributes.id",
                             :conditions => [ "annotation_attributes.name = ?", 
                                              attrib_name.strip.downcase ],
                             :order => "created_at DESC")
  end
end