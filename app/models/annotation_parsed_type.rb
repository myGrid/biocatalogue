class AnnotationParsedType < ActiveRecord::Base
  belongs_to :annotation
  
  validates_presence_of :parsed_type, :annotation
end
