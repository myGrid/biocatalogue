class Annotation < ActiveRecord::Base
  belongs_to :annotatable, :polymorphic => true
  validates_presence_of :key
end
