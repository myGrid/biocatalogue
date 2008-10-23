class Annotation < ActiveRecord::Base
  belongs_to :annotatable, :polymorphic => true
  
  # NOTE: install the acts_as_votable plugin if you 
  # want user to vote on the quality of annotations.
  #acts_as_voteable
  
  # NOTE: Annotations belong to a user
  belongs_to :user
  
  # Helper class method to lookup all annotations assigned
  # to all annotatable types for a given user.
  def self.find_annotations_by_user(user)
    find(:all,
      :conditions => ["user_id = ?", user.id],
      :order => "created_at DESC"
    )
  end
  
  # Helper class method to look up all annotations for 
  # annotatable class name and annotatable id.
  def self.find_annotations_for_annotatable(annotatable_str, annotatable_id)
    find(:all,
      :conditions => ["annotatable_type = ? and annotatable_id = ?", annotatable_str, annotatable_id],
      :order => "created_at DESC"
    )
  end

  # Helper class method to look up an annotatable object
  # given the annotatable class name and id 
  def self.find_annotatable(annotatable_str, annotatable_id)
    annotatable_str.constantize.find(annotatable_id)
  end
end