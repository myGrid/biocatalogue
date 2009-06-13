class Annotation < ActiveRecord::Base
  include AnnotationsVersionFu
  
  before_validation_on_create :set_default_value_type
  
  before_validation :process_value_adjustments
  
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
                        
  validate :check_annotatable,
           :check_source,
           :check_duplicate,
           :check_limit_per_source,
           :check_value_restrictions
           
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
  # given the annotatable class name and ID. 
  def self.find_annotatable(annotatable_type, annotatable_id)
    return nil if annotatable_type.nil? or annotatable_id.nil?
    begin
      return annotatable_type.constantize.find(annotatable_id)
    rescue
      return nil
    end
  end
  
  # Helper class method to look up a source object
  # given the source class name and ID. 
  def self.find_source(source_type, source_id)
    return nil if source_type.nil? or source_id.nil?
    begin
      return source_type.constantize.find(source_id)
    rescue
      return nil
    end
  end
  
  def attribute_name
    self.attribute.name
  end
  
  def attribute_name=(attr_name)
    attr_name = attr_name.to_s.strip
    self.attribute = AnnotationAttribute.find_or_create_by_name(attr_name)
  end
  
  def value=(value_in)
    self[:value] = value_in.to_s
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
  
  # ===========
  # Validations
  # -----------
  
  def check_annotatable
    if Annotation.find_annotatable(self.annotatable_type, self.annotatable_id).nil?
      self.errors.add(:annotatable_id, "doesn't exist")
      return false
    else
      return true
    end
  end
  
  def check_source
    if Annotation.find_source(self.source_type, self.source_id).nil?
      self.errors.add(:source_id, "doesn't exist")
      return false
    else
      return true
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
                                 :joins => [ :attribute ],
                                 :conditions => { :annotatable_type =>  self.annotatable_type, 
                                                  :annotatable_id => self.annotatable_id, 
                                                  :value => self.value,
                                                  :annotation_attributes => { :name => attr_name  } })
      
      if existing.length == 0 or existing[0].id == self.id
        # It's all good...
        return true
      else
        self.errors.add_to_base("This annotation already exists and is not allowed to be created again.")
        return false
      end
    end
  end
  
  # This method uses the 'limits_per_source config' setting to check whether a limit has been reached.
  #
  # NOTE: this check is only carried out on new records, not records that are being updated.
  def check_limit_per_source
    attr_name = self.attribute_name.downcase
    if self.new_record? and Annotations::Config::limits_per_source.has_key?(attr_name)
      options = Annotations::Config::limits_per_source[attr_name]
      max = options[0]
      can_replace = options[1]
      
      unless (found_annotatable = Annotation.find_annotatable(self.annotatable_type, self.annotatable_id)).nil?
        anns = found_annotatable.annotations_with_attribute_and_by_source(attr_name, self.source)
        
        if anns.length >= max
          self.errors.add_to_base("The limit has been reached for annotations with this attribute and by this source.")
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
  
  def check_value_restrictions
    attr_name = self.attribute_name.downcase
    value_to_check = self.value.downcase
    if Annotations::Config::value_restrictions.has_key?(attr_name)
      options = Annotations::Config::value_restrictions[attr_name]
      
      case options[:in]
        when Array
          if options[:in].map{|s| s.downcase}.include?(value_to_check)
            return true
          else
            self.errors.add_to_base(options[:error_message])
            return false
          end
          
        when Range
          # Need to take into account that "a_string".to_i == 0
          if value_to_check == "0"
            if options[:in] === 0
              return true
            else
              self.errors.add_to_base(options[:error_message])
              return false
            end
          else
            if options[:in] === value_to_check.to_i
              return true
            else
              self.errors.add_to_base(options[:error_message])
              return false
            end
          end
          
        else
          return true
      end
    else
      return true
    end      
  end
  
  # ===========
end