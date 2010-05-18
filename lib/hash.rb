# This provides some extensions to the Hash class.
#
# One of which is an improved "from_xml" method that takes into account attributes.
# This was provided by Tod Jackson, from Emory University.

class Hash
  
  def self.better_from_xml(xml, options = {})
    Rails.logger.info("hash.rb:  better_from_xml called.")
    return better_typecast_xml_value(unrename_keys(ActiveSupport::XmlMini.parse(xml)), options)
  end
  
  private
  
  def self.better_typecast_xml_value(value, options = {})
    options.symbolize_keys!
    options.reverse_merge!(:preserve_attributes => false)
    
    case value.class.to_s
      when 'Hash'
      if value['type'] == 'array'
        child_key, entries = value.detect { |k,v| k != 'type' }   # child_key is throwaway
        if entries.nil? || (c = value['__content__'] && c.blank?)
          []
        else
          case entries.class.to_s   # something weird with classes not matching here.  maybe singleton methods breaking is_a?
            when "Array"
            entries.collect { |v| better_typecast_xml_value(v, options) }
            when "Hash"
            [better_typecast_xml_value(entries, options)]
          else
            raise "can't typecast #{entries.inspect}"
          end
        end
      elsif value.has_key?("__content__")
        content = value["__content__"]
        if parser = XML_PARSING[value["type"]]
          if parser.arity == 2
            XML_PARSING[value["type"]].call(content, value)
          else
            XML_PARSING[value["type"]].call(content)
          end
        elsif options[:preserve_attributes] && value.keys.size > 1
          value["content"] = value.delete("__content__")
          value
        else
          content
        end
      elsif value['type'] == 'string' && value['nil'] != 'true'
                    ""
        # blank or nil parsed values are represented by nil
      elsif value.blank? || value['nil'] == 'true'
        nil
        # If the type is the only element which makes it then
        # this still makes the value nil, except if type is
        # a XML node(where type['value'] is a Hash)
      elsif value['type'] && value.size == 1 && !value['type'].is_a?(::Hash)
        nil
      else
        xml_value = value.inject({}) do |h,(k,v)|
          h[k] = better_typecast_xml_value(v, options)
          h
        end
        
        # Turn { :files => { :file => #<StringIO> } into { :files => #<StringIO> } so it is compatible with
        # how multipart uploaded files from HTML appear
        xml_value["file"].is_a?(StringIO) ? xml_value["file"] : xml_value
      end
      when 'Array'
      value.map! { |i| better_typecast_xml_value(i, options) }
      case value.length
        when 0 then nil
        when 1 then value.first
      else value
      end
      when 'String'
      value
    else
      raise "can't typecast #{value.class.name} - #{value.inspect}"
    end
  end
  
end