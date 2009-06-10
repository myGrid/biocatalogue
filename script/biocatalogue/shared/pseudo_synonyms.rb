# Common methods used in the various pseudo synonyms processing scripts.

# See pseudo_synonyms_test.rb for example usage.

module PseudoSynonyms
  
  SUBSTITUTES = { "Structure and Function Prediction" => [ "Prediction", "Structure Prediction", "Function Prediction" ] }
  
  # Checks for substitutes etc.
  # Always returns an Array
  def process_values(*vals)
    return [ ] if vals.nil?
    
    final = [ ]
    
    vals.each do |v|
      case v
        when String
          final << (SUBSTITUTES.has_key?(v) ? SUBSTITUTES[v] : v)
        when Array
          v.each do |x|
            final << process_values(x)
          end
      end
    end
    
    return final.flatten.uniq
  end
  
  # Always returns an Array.
  def underscored_and_spaced_versions_of(*vals)
    return [ ] if vals.nil?
    
    final = [ ]
    
    vals.each do |v|
      case v
        when String
          final << v
          final << v.gsub(" ", "_") if v.include?(" ")
          final << v.gsub("_", " ") if v.include?("_")
        when Array
          v.each do |x|
            final << underscored_and_spaced_versions_of(x)
          end
      end
    end
    
    return final.flatten.uniq
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