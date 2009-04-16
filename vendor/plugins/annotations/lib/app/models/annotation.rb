class Annotation < ActiveRecord::Base
  include AnnotationsVersionFu
  
  before_validation_on_create :set_default_value_type
  
  before_save :check_annotatable
  
  before_save :process_value_adjustments
  
  before_save :check_duplicate
  
  before_save :check_limit
  
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
  #
  # NOTE (1): both the attribute name and the value will be treated case insensitively.
  def self.find_annotatables_with_attribute_name_and_value(attribute_name, value)
    return [ ] if attribute_name.blank? or value.nil?
    
    anns = Annotation.find(:all,
                           :joins => :attribute,
                           :conditions => { :annotation_attributes =>  { :name => attribute_name.strip.downcase }, 
                                            :value => value.strip.downcase })
                                                  
    return anns.map{|a| a.annotatable}
  end
  
  # Same as the Annotation.find_annotatables_with_attribute_name_and_value method but 
  # takes in arrays for attribute names and values.
  #
  # This allows you to build any combination of attribute names and values to search on.
  # E.g. (1): Annotation.find_annotatables_with_attribute_names_and_values([ "tag" ], [ "fiction", "sci-fi", "fantasy" ])
  # E.g. (2): Annotation.find_annotatables_with_attribute_names_and_values([ "tag", "keyword", "category" ], [ "fiction", "fantasy" ])
  #
  # NOTE (1): the arguments to this method MUST be Arrays of Strings.
  # NOTE (2): all attribute names and the values will be treated case insensitively.
  def self.find_annotatables_with_attribute_names_and_values(attribute_names, values)
    return [ ] if attribute_names.blank? or values.blank?
    
    anns = Annotation.find(:all,
                           :joins => :attribute,
                           :conditions => { :annotation_attributes =>  { :name => attribute_names }, 
                                            :value => values })
    
    return anns.map{|a| a.annotatable}
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
  
  # Finder to get all annotations with a given attribute_name.
  named_scope :with_attribute_name, lambda { |attrib_name|
    { :conditions => { :annotation_attributes => { :name => attrib_name } },
      :joins => :attribute,
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
    attr_name = self.attribute_name.downcase
    # Make lowercase or uppercase if required
    self.value.downcase! if Annotations::Config::attribute_names_for_values_to_be_downcased.include?(attr_name)
    self.value.upcase! if Annotations::Config::attribute_names_for_values_to_be_upcased.include?(attr_name)
    
    # Apply strip text rules
    Annotations::Config::strip_text_rules.each do |attr, strip_rules|
      if attr_name == attr.downcase
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
  
  # This method checks whether duplicates are allowed for this particular annotation type (ie: 
  # for the attribute that this annotation belongs to). If not, it checks for a duplicate existing annotation.
  def check_duplicate
    attr_name = self.attribute_name.downcase
    if Annotations::Config.attribute_names_to_allow_duplicates.include?(attr_name)
      return true
    else
      existing = Annotation.find(:all,
                                 :joins => "JOIN annotation_attributes ON annotations.attribute_id = annotation_attributes.id",
                                 :conditions => [ "annotations.annotatable_type = ? AND annotations.annotatable_id = ? AND annotation_attributes.name = ? AND annotations.value = ?", 
                                                  self.annotatable_type,
                                                  self.annotatable_id,
                                                  attr_name,
                                                  self.value ])
      
      if existing.length == 0
        # It's all good...
        return true
      else
        self.errors.add_to_base("This annotation already exists and is not allowed to be created again.")
        return false
      end
    end
  end
  
  # This method uses the limits_per_source config setting
  # to check whether a limit has been reached and takes appropriate action if it has.
  #
  # If a limit has been reach and the limit is 1 and the replace existing otion is true, 
  # it will overwrite the value of the existing annotation and then stop the save procedure. 
  # Otherwise it will just stop the save procedure.
  def check_limit
    attr_name = self.attribute_name.downcase
    if Annotations::Config::limits_per_source.has_key?(attr_name)
      options = Annotations::Config::limits_per_source[attr_name]
      max = options[0]
      can_replace = options[1]
      
      unless (found_annotatable = Annotation.find_annotatable(self.annotatable_type, self.annotatable_id)).nil?
        anns = found_annotatable.annotations_with_attribute_and_by_source(attr_name, self.source)
        
        # If this annotation is being updated (not created), remove it from the anns collection.
        # This prevents an infinite loop when an existing annotation is being updated as further below.
        unless self.new_record?
          anns.each do |a|
            anns.delete(a) if a.id == self.id
          end
        end
      
        if anns.length >= max
          # Only update an existing annotation if the limit is 1, AND 
          # only one existing was found (it's possible that this config was introduced afterwards 
          # in a situation where the limit has already been surpassed previously, so we need this check), AND
          # the config option says that we can replace it. 
          if max == 1 && anns.length == 1 && can_replace
            ann = anns[0]
            
            # Because the object is read only, load it up again.
            ann2 = Annotation.find(ann.id)
            
            ann2.value = self.value
            ann2.save
            self.errors.add_to_base("The limit has been reached for annotations with this attribute and by this source. The existing annotation has been updated.")
          else
            self.errors.add_to_base("The limit has been reached for annotations with this attribute and by this source. No further action has been taken.")
          end
          
          return false
        else
          return true
        end
      else
        return true
      end
    else
      return true
    end
  end
end