# BioCatalogue: lib/bio_catalogue/json.rb
#
# Copyright (c) 2010, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# Module to abstract out any specific processing for the REST XML/JSON/etc API

module BioCatalogue
  module JSON
  
    # JSON Output Helpers
    
    def self.monitoring_status(status)
      {
        "label" => status.label,
        "message" => status.message,
        "symbol" => BioCatalogue::Api.uri_for_path("/images/#{status.symbol_filename}"),
        "small_symbol" => BioCatalogue::Api.uri_for_path("/images/#{status.small_symbol_filename}"),
        "last_checked" => (status.last_checked.iso8601 || "")
      }
    end # self.json_for_monitoring_status
    
    def self.location(country, city="")
      country_code = (CountryCodes.code(country) || "")
      
      {
        "city" => (city || ""),
        "country" => (country || ""),
        "country_code" => country_code,
        "flag" => (BioCatalogue::Api.uri_for_path(BioCatalogue::Resource.flag_icon_path(country_code)) || "")
      }
    end # self.json_for_location
    
    def self.collection(collection, make_inline)
      make_inline = true unless make_inline.class.name =~ /TrueClass|FalseClass/
      
      list = []
        
      collection.each do |item|
        if make_inline
          list << JSON(item.to_inline_json)
        else
          list << JSON(item.to_json)
        end
      end
      
      return list
    end
      
  end
end