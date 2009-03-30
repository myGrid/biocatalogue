module Annotations
  module Config
    # Attribute name(s) that need the corresponding value to be downcased (made all lowercase).
    # 
    # NOTE: The attribute names specified MUST all be in lowercase.
    @@attribute_names_for_values_to_be_downcased = [ ]
    
    # Attribute name(s) that need the corresponding value to be upcased (made all uppercase).
    #
    # NOTE: The attribute names specified MUST all be in lowercase.
    @@attribute_names_for_values_to_be_upcased = [ ]
    
    # This defines a hash of attributes, and the characters/strings that need to be stripped (removed) out of values of the attributes specified.
    # Regular expressions can also be used instead of characters/strings.
    # ie: { attribute => [ array of characters to strip out ] }    (note: doesn't have to be an array, can be a single string)
    #
    # e.g: { "tag" => [ '"', ','] } or { "tag" => '"' }
    # 
    # NOTE: The attribute name(s) specified MUST all be in lowercase.  
    @@strip_text_rules = { }
    
    # This allows you to specify a different model name for users in the system (if different from the default: "User").
    @@user_model_name = "User"
    
    # This allows you to limit the number of annotations (of specified attribute names) per source per annotatable.
    # Key/value pairs in hash should follow the spec:
    # { :attribute_name => [ max_number_allowed, should_replace_existing? ] }
    #
    # e.g: { "rating" => [ 1, true ] } will only ever allow 1 "rating" annotation per annotatable by each source.
    #
    # NOTE (1): The attribute name(s) specified MUST all be in lowercase.
    # NOTE (2): The should_replace_existing? option is only used if the max_number_allowed is set to 1.
    @@limits_per_source = { }
    
    # By default, duplicate annotations cannot be created (same value for the same attribute, on an annotatable object, regardless of source). 
    # For example: a user cannot add a description to a book that matches an existing description for that book.
    # 
    # This config setting allows exceptions to this rule, on a per attribute basis. 
    # I.e: allow annotations with certain attribute names to have duplicate values.
    #
    # The format for the setting is:
    # [ "attribute_name_1", "attribute_name_2", ... ]
    #
    # e.g: [ "tag", "rating" ]
    #
    # NOTE (1): The attribute name(s) specified MUST all be in lowercase.
    # NOTE (2): This setting can be used in conjunction with the limits_per_source setting to allow duplicate annotations 
    # BUT limit the number of annotations (per attribute) per user.
    @@attribute_names_to_allow_duplicates = [ ]
    
    
    # This makes the variables above available externally.
    # Shamelessly borrowed from the GeoKit plugin.
    [ :attribute_names_for_values_to_be_downcased,
      :attribute_names_for_values_to_be_upcased,
      :strip_text_rules,
      :user_model_name,
      :limits_per_source,
      :attribute_names_to_allow_duplicates ].each do |sym|
      class_eval <<-EOS, __FILE__, __LINE__
        def self.#{sym}
          if defined?(#{sym.to_s.upcase})
            #{sym.to_s.upcase}
          else
            @@#{sym}
          end
        end

        def self.#{sym}=(obj)
          @@#{sym} = obj
        end
      EOS
    end
  end
end