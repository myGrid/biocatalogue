class Annotation < ActiveRecord::Base
  acts_as_trashable
  
  belongs_to :annotatable, :polymorphic => true
  validates_presence_of :key
end
