module NumbersUtil
  
  def number_with_delimiter(number, options = {})
    options.symbolize_keys!
    
    begin
      Float(number)
    rescue ArgumentError, TypeError
      if options[:raise]
        raise InvalidNumberError, number
      else
        return number
      end
    end
    
    defaults = I18n.translate(:'number.format', :locale => options[:locale], :default => {})
    options = options.reverse_merge(defaults)
    
    parts = number.to_s.split('.')
    parts[0].gsub!(/(\d)(?=(\d\d\d)+(?!\d))/, "\\1#{options[:delimiter]}")
    parts.join(options[:separator])
  end
  
end