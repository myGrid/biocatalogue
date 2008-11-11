# BioCatalogue: app/lib/country_codes.rb
#
# Copyright (c) 2008, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

module CountryCodes
  @@codes = Hash.new
  File.open('config/countries.tab').each do |record|
    parts = record.split("\t")
    @@codes[parts[0]] = parts[1].strip
  end
  
  #puts "countries = " + @@codes.to_s
  
  def self.country(code)
    code = "GB" if code.upcase == "UK" 
    @@codes[code]
  end
  
  def self.code(country)
    c = nil
    @@codes.each do |key, val|
      if(country.downcase.strip == val.downcase)
        c = key.downcase
        break
      end
    end
    return c
  end
  
  def self.valid_code?(code)
    @@codes.key?(code)
  end
end