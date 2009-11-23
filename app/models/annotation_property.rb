class AnnotationProperty < ActiveRecord::Base
  belongs_to :annotation
  belongs_to :property, :polymorphic =>true
  
  validates_presence_of :annotation, :property, :value
  
end
