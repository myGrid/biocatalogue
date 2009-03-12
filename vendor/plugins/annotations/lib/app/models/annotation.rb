class Annotation < ActiveRecord::Base
  include AnnotationsVersionFu
  
  before_validation_on_create :set_default_value_type
  
  before_save :check_annotatable
  
  before_save :process_value_adjustments
  
  belongs_to :annotatable, 
             :polymorphic => true
  
  belongs_to :source, 
             :polymorphic => true
             
  belongs_to :attribute,
             :class_name => "AnnotationAttribute",
             :foreign_key => "attribute_id"

  belongs_to :version_creator, 
             :class_name => Annotations::Config.user_model_name
  
  validates_presence_of :source_type,
                        :source_id,
                        :annotatable_type,
                        :annotatable_id,
                        :attribute_id,
                        :value,
                        :value_type
  
  # ========================
  # Versioning configuration
  # ------------------------
  
  annotations_version_fu do
    belongs_to :annotatable, 
               :polymorphic => true
    
    belongs_to :source, 
               :polymorphic => true
               
    belongs_to :attribute,
               :class_name => "AnnotationAttribute",
               :foreign_key => "attribute_id"
             
    belongs_to :version_creator, 
               :class_name => "::#{Annotations::Config.user_model_name}"
    
    validates_presence_of :source_type,
                          :source_id,
                          :annotatable_type,
                          :annotatable_id,
                          :attribute_id,
                          :value,
                          :value_type
  end
  
  # ========================
  
  # Returns all the annotatable objects that have a specified attribute name and value.
  # Note: both the attribute name and the value will be treated case insensitively.
  def self.find_annotatables_with_attribute_name_and_value(attribute_name, value)
    return [ ] if attribute_name.blank? or value.nil?
    
    anns = Annotation.find(:all,
                           :joins => "JOIN annotation_attributes ON annotations.attribute_id = annotation_attributes.id",
                           :conditions => [ "annotation_attributes.name = ? AND annotations.value = ?", 
                                            attribute_name.strip.downcase,
                                            value.strip.downcase ])
                                                  
    return anns.map{|a| a.annotatable}.uniq
  end
  
  # Finder to get all annotations by a given source.
  named_scope :by_source, lambda { |source_type, source_id| 
    { :conditions => { :source_type => source_type, 
                       :source_id => source_id },
      :order => "created_at DESC" }
  }
  
  # Finder to get all annotations for a given annotatable.
  named_scope :for_annotatable, lambda { |annotatable_type, annotatable_id| 
    { :conditions => { :annotatable_type =>  annotatable_type, 
                       :annotatable_id => annotatable_id },
      :order => "created_at DESC" }
  }
  
  # Helper class method to look up an annotatable object
  # given the annotatable class name and id 
  def self.find_annotatable(annotatable_type, annotatable_id)
    return nil if annotatable_type.nil? or annotatable_id.nil?
    begin
      return annotatable_type.constantize.find(annotatable_id)
    rescue
      return nil
    end
  end
  
  def attribute_name
    self.attribute.name
  end
  
  def attribute_name=(attr_name)
    attr_name = ( attr_name.is_a?(String) ? attr_name.strip : attr_name.to_s )
    self.attribute = AnnotationAttribute.find_or_create_by_name(attr_name)
  end
  
  def self.create_multiple(params, separator)
    success = true
    annotations = [ ]
    errors = [ ]
    
    annotatable = Annotation.find_annotatable(params[:annotatable_type], params[:annotatable_id])
    
    if annotatable
      values = params[:value]
      
      # Remove value from params hash
      params.delete("value")
      
      values.split(separator).each do |val|
        ann = Annotation.new(params)
        ann.value = val.strip
        
        if ann.save
          annotations << ann
        else
          error_text = "Error(s) occurred whilst saving annotation with attribute: '#{params[:attribute_name]}', and value: #{val} - #{ann.errors.full_messages.to_sentence}." 
          errors << error_text
          logger.info(error_text)
          success = false
        end
      end
    else
      errors << "Annotatable object doesn't exist"
      success = false
    end
     
    return [ success, annotations, errors ]
  end
  
  protected
  
  def set_default_value_type
    self.value_type = "String" if self.value_type.blank?
  end
  
  def check_annotatable
    if Annotation.find_annotatable(self.annotatable_type, self.annotatable_id).nil?
      self.errors.add(:annotatable_id, "doesn't exist")
      return false
    else
      return true
    end
  end
  
  def process_value_adjustments
    # Make lowercase or uppercase if required
    self.value.downcase! if Annotations::Config::attribute_names_for_values_to_be_downcased.include?(self.attribute_name.downcase)
    self.value.upcase! if Annotations::Config::attribute_names_for_values_to_be_upcased.include?(self.attribute_name.downcase)
    
    # Apply strip text rules
    Annotations::Config::strip_text_rules.each do |attr, strip_rules|
      if self.attribute_name.downcase == attr.downcase
        if strip_rules.is_a? Array
          strip_rules.each do |s|
            self.value = self.value.gsub(s, '')
          end
        elsif strip_rules.is_a? String or strip_rules.is_a? Regexp
          self.value = self.value.gsub(strip_rules, '')
        end
      end
    end
  end
end