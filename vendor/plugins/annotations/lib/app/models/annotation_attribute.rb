class AnnotationAttribute < ActiveRecord::Base
  validates_presence_of :name
  
  validates_uniqueness_of :name,
                          :case_sensitive => false
                          
  has_many :annotations,
           :foreign_key => "attribute_id"
end