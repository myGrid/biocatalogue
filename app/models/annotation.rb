class Annotation < ActiveRecord::Base
  belong_to :annotatable, :polymorphic => true
  validates_presence_of :key
end
