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
    # e.g: { "tag" => [ '"', ','] } or { "tag" => '"' }
    # 
    # NOTE: The attribute names specified MUST all be in lowercase.    
    @@strip_text_rules = { }
    
    # This allows you to specify a different model name for users in the system (if different from the default: "User").
    @@user_model_name = "User"
    
    # This makes the variables above available externally.
    # Shamelessly borrowed from GeoKit.
    [ :attribute_names_for_values_to_be_downcased,
      :attribute_names_for_values_to_be_upcased,
      :strip_text_rules,
      :user_model_name ].each do |sym|
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