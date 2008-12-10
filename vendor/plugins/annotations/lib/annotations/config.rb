module Annotations
  module Config
    # Attribute name(s) that need the corresponding value to be downcased (made all lowercase). 
    # The attribute names specified MUST all be in lowercase.
    @@attribute_names_for_values_to_be_downcased = [ ]
    
    # Attribute name(s) that need the corresponding value to be upcased (made all uppercase). 
    # The attribute names specified MUST all be in lowercase.
    @@attribute_names_for_values_to_be_upcased = [ ]
    
    # This makes the variables above available externally.
    # Shamelessly borrowed from GeoKit.
    [ :attribute_names_for_values_to_be_downcased,
      :attribute_names_for_values_to_be_upcased ].each do |sym|
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