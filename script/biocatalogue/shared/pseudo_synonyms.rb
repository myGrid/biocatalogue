# Common methods used in the various pseudo synonyms processing scripts.

# See pseudo_synonyms_test.rb for example usage.

module PseudoSynonyms
  
  SUBSTITUTES = { "Structure and Function Prediction" => [ "Prediction", "Structure Prediction", "Function Prediction" ] }
  
  # Always returns an Array
  def process_values(*vals)
    return [ ] if vals.nil?
    
    final = [ ]
    
    vals.each do |v|
      case v
        when String
          final << process_value(v)
        when Array
          v.each do |x|
            final << process_values(x)
          end
      end
    end
    
    return final.flatten.uniq
  end
  
  # Checks for substitutes;
  # Produces underscored and spaced version.
  #
  # Always returns an Array.
  def process_value(val)
    return [ ] if val.nil?
    
    if SUBSTITUTES.has_key?(val)
      return SUBSTITUTES[val]
    else
      return [ val ]
    end
  end
  
  # Always returns an Array.
  def underscored_and_spaced_versions_of(val)
    return [ ] if val.nil?
    
    final = [ ]
    final << val
    
    final << val.gsub(" ", "_") if val.include?(" ")
    final << val.gsub("_", " ") if val.include?("_")
    
    return final.uniq
  end
  
  def to_list(x)
    return "" if x.nil?
    
    case x.length
      when 0
         ""
      when 1
        x[0].to_s
      else
        x.join(',')
    end
  end
  
end