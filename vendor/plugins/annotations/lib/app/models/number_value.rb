class NumberValue < ActiveRecord::Base
  include AnnotationsVersionFu
  
  validates_presence_of :number
  
  acts_as_annotation_value :content_field => :number
  
  belongs_to :version_creator, 
             :class_name => "::#{Annotations::Config.user_model_name}"

  def to_s
    self.ann_content
  end

  # ========================
  # Versioning configuration
  # ------------------------
  
  annotations_version_fu do
    validates_presence_of :number
    
    belongs_to :version_creator, 
               :class_name => "::#{Annotations::Config.user_model_name}"
  end
  
  # ========================
end
